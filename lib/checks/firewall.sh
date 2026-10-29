#!/usr/bin/env bash

report_firewall_status() {
  local detected_count="$1"
  local active_tools="$2"
  local inactive_tools="$3"
  local unknown_tools="$4"

  if [[ -n "$active_tools" ]]; then
    add_finding firewall info "Firewall active" \
      "Active firewall configuration detected through $(sanitize_text "$active_tools")."
  elif [[ -n "$unknown_tools" ]]; then
    add_finding firewall info "Firewall status unknown" \
      "Firewall tooling was detected, but its status could not be determined through $(sanitize_text "$unknown_tools")." \
      "Run the audit with sufficient read permissions or inspect the firewall manually."
  elif (( detected_count > 0 )); then
    add_finding firewall warning "Firewall inactive" \
      "Detected firewall tooling is inactive: $(sanitize_text "$inactive_tools")." \
      "Enable and configure a host firewall when network policy requires one."
  else
    add_finding firewall warning "Firewall tooling unavailable" \
      "UFW, firewalld, and nftables tooling were not detected." \
      "Confirm that network filtering is provided by the host or its environment."
  fi
}

run_firewall_check() {
  local detected_count=0
  local active_tools=()
  local inactive_tools=()
  local unknown_tools=()

  if command_exists ufw; then
    ((detected_count += 1))
    if capture_command ufw status; then
      if [[ "$COMMAND_OUTPUT" == *"Status: active"* ]]; then
        active_tools+=("UFW")
      elif [[ "$COMMAND_OUTPUT" == *"Status: inactive"* ]]; then
        inactive_tools+=("UFW")
      else
        unknown_tools+=("UFW")
      fi
    else
      unknown_tools+=("UFW")
    fi
  fi

  if command_exists firewall-cmd; then
    ((detected_count += 1))
    if capture_command firewall-cmd --state; then
      if [[ "$COMMAND_OUTPUT" == "running" ]]; then
        active_tools+=("firewalld")
      else
        unknown_tools+=("firewalld")
      fi
    elif [[ "$COMMAND_OUTPUT" == "not running" ]]; then
      inactive_tools+=("firewalld")
    else
      unknown_tools+=("firewalld")
    fi
  fi

  if command_exists nft; then
    ((detected_count += 1))
    if capture_command nft list ruleset; then
      if [[ -n "$COMMAND_OUTPUT" ]]; then
        active_tools+=("nftables")
      else
        inactive_tools+=("nftables")
      fi
    else
      unknown_tools+=("nftables")
    fi
  fi

  report_firewall_status "$detected_count" \
    "$(join_by ', ' "${active_tools[@]-}")" \
    "$(join_by ', ' "${inactive_tools[@]-}")" \
    "$(join_by ', ' "${unknown_tools[@]-}")"
}
