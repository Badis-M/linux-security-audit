#!/usr/bin/env bash

socket_is_wildcard() {
  case "$1" in
    0.0.0.0:*|'[::]':*|:::*|'*':*) return 0 ;;
    *) return 1 ;;
  esac
}

# Validate numeric endpoints before applying the expected-port policy.
network_ipv4_is_valid() {
  local address="$1" octet
  local -a octets
  [[ "$address" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || return 1
  IFS=. read -r -a octets <<< "$address"
  for octet in "${octets[@]}"; do
    (( ${#octet} <= 3 )) && (( 10#$octet <= 255 )) || return 1
  done
}

network_zone_is_valid() {
  local zone="$1" LC_ALL=C
  # Linux interface names occupy 1-15 bytes and cannot be "." or "..",
  # or contain whitespace, "/" or ":". Also reject endpoint delimiters.
  [[ -n "$zone" && ${#zone} -le 15 && "$zone" != . && "$zone" != .. ]] || return 1
  [[ "$zone" != *[[:space:]]* && "$zone" != */* && "$zone" != *:* &&
     "$zone" != *%* && "$zone" != *'['* && "$zone" != *']'* ]]
}

network_ipv6_is_valid() {
  local address="$1" tail group expanded zone count=0
  local -a groups
  # Validate the optional scope before removing it; empty/repeated zones fail.
  if [[ "$address" == *%* ]]; then
    zone="${address#*%}"
    network_zone_is_valid "$zone" || return 1
    address="${address%%\%*}"
  fi
  # Accept IPv4 tails as emitted by ss.
  if [[ "$address" == *.* ]]; then
    tail="${address##*:}"
    network_ipv4_is_valid "$tail" || return 1
    address="${address%:*}:0:0"
  fi
  [[ "$address" == *:* && "$address" != *:::* ]] || return 1
  [[ "$address" != :* || "$address" == ::* ]] || return 1
  [[ "$address" != *: || "$address" == *:: ]] || return 1
  if [[ "$address" == *::* ]]; then
    tail="${address#*::}"
    [[ "$tail" != *::* ]] || return 1
    expanded="${address/::/:}"
  else
    [[ "$address" != :* && "$address" != *: ]] || return 1
    expanded="$address"
  fi
  IFS=: read -r -a groups <<< "$expanded"
  for group in "${groups[@]}"; do
    [[ -n "$group" ]] || continue
    [[ "$group" =~ ^[[:xdigit:]]{1,4}$ ]] || return 1
    ((count += 1))
  done
  if [[ "$address" == *::* ]]; then
    (( count < 8 ))
  else
    (( count == 8 ))
  fi
}

classify_expected_tcp_socket() {
  local endpoint="$1" address port expected ipv6=0 compact
  local bracket_pattern='^\[([^][]+)\](%([^][]*))?:([0-9]+)$'
  if [[ "$endpoint" == \[* ]]; then
    # Match the entire endpoint, not just its last colon-delimited field.
    [[ "$endpoint" =~ $bracket_pattern ]] || return 1
    # Normalize both [address%zone]:port and ss's [address]%zone:port.
    # Combining the scopes makes duplicate inner/outer zones fail validation.
    address="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
    port="${BASH_REMATCH[4]}"
    ipv6=1
  else
    address="${endpoint%:*}"
    port="${endpoint##*:}"
    [[ "$address" != *:* ]] || ipv6=1
  fi
  if [[ "$endpoint" != *:* || ! "$port" =~ ^[0-9]+$ ]]; then
    return 1
  fi
  while [[ "${#port}" -gt 1 && "$port" == 0* ]]; do port="${port#0}"; done
  (( ${#port} <= 5 )) && (( 10#$port >= 1 && 10#$port <= 65535 )) || return 1
  port="$((10#$port))"
  if (( ipv6 )); then
    network_ipv6_is_valid "$address" || return 1
    compact="${address%%%*}"
    compact="${compact//:/}"
    compact="${compact//0/}"
    # A valid IPv6 address with only a final 1 is the loopback address.
    if [[ "$compact" == 1 && "${address%%%*}" == *1 ]]; then
      return 0
    fi
  elif [[ "$address" != "*" ]]; then
    network_ipv4_is_valid "$address" || return 1
    if (( 10#${address%%.*} == 127 )); then return 0; fi
  fi
  # The ss wildcard address "*" is non-loopback and uses the same port list.
  for expected in "${CLI_EXPECTED_TCP_PORTS[@]}"; do
    [[ "$port" != "$expected" ]] || return 0
  done
  return 1
}

report_listening_sockets() {
  local socket_output="$1"
  local protocol _state _receive_queue _send_queue local_address _peer_address
  local socket_count=0

  while read -r protocol _state _receive_queue _send_queue local_address _peer_address _; do
    case "$protocol" in
      tcp|udp) ;;
      *) continue ;;
    esac
    [[ -n "$local_address" ]] || continue
    ((socket_count += 1))
    if [[ "$protocol" == tcp && -n "${CLI_EXPECTED_TCP_PORTS[*]-}" ]]; then
      if classify_expected_tcp_socket "$local_address"; then
        add_finding network info "Listening socket" \
          "tcp is listening on $(sanitize_text "$local_address")."
      else
        add_finding network warning "Unexpected TCP listening port" \
          "tcp listening endpoint $(sanitize_text "$local_address") is not a valid local or expected TCP endpoint." \
          "Review the listening service and the expected TCP port list."
      fi
    elif socket_is_wildcard "$local_address"; then
      add_finding network warning "Wildcard listening socket" \
        "$(sanitize_text "$protocol") is listening on $(sanitize_text "$local_address"), which accepts connections on any local interface." \
        "Confirm that the service requires network-wide exposure and restrict it when possible."
    else
      add_finding network info "Listening socket" \
        "$(sanitize_text "$protocol") is listening on $(sanitize_text "$local_address")."
    fi
  done <<< "$socket_output"

  if (( socket_count == 0 )); then
    add_finding network info "No listening sockets" \
      "No listening TCP or UDP sockets were reported by ss."
  fi
}

run_network_check() {
  if ! command_exists ss; then
    add_finding network info "Socket inventory unavailable" \
      "The ss command is not available." \
      "Install the iproute2 package to enable socket inspection."
    return 0
  fi

  # Process details are deliberately excluded to avoid unnecessary disclosure.
  if capture_command ss -H -lntu; then
    report_listening_sockets "$COMMAND_OUTPUT"
  else
    add_finding network info "Socket inventory unavailable" \
      "Listening sockets could not be queried with ss." \
      "Review host permissions and network namespace access."
  fi
}
