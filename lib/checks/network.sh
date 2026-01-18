#!/usr/bin/env bash

socket_is_wildcard() {
  case "$1" in
    0.0.0.0:*|'[::]':*|:::*|'*':*) return 0 ;;
    *) return 1 ;;
  esac
}

report_listening_sockets() {
  local socket_output="$1"
  local protocol state receive_queue send_queue local_address peer_address
  local socket_count=0

  while read -r protocol state receive_queue send_queue local_address peer_address _; do
    [[ -n "$protocol" && -n "$local_address" ]] || continue
    ((socket_count += 1))
    if socket_is_wildcard "$local_address"; then
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
