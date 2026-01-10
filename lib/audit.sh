#!/usr/bin/env bash

REGISTERED_CHECKS=(system services network ssh firewall permissions resources updates)
CHECK_DESCRIPTIONS=(
  "System distribution, kernel, uptime, and privilege inventory"
  "Failed systemd service units"
  "Listening TCP and UDP sockets"
  "Evaluated OpenSSH server configuration"
  "UFW, firewalld, or nftables status"
  "Sensitive account file metadata"
  "Disk, inode, memory, and swap health"
  "Debian-family package update posture"
)

is_registered_check() {
  array_contains "$1" "${REGISTERED_CHECKS[@]}"
}

validate_check_selection() {
  local check_name
  for check_name in "${CLI_ONLY_CHECKS[@]-}" "${CLI_EXCLUDED_CHECKS[@]-}"; do
    [[ -n "$check_name" ]] || continue
    if ! is_registered_check "$check_name"; then
      CLI_ERROR="Unknown check: $check_name"
      return 3
    fi
  done

  for check_name in "${CLI_ONLY_CHECKS[@]-}"; do
    [[ -n "$check_name" ]] || continue
    if array_contains "$check_name" "${CLI_EXCLUDED_CHECKS[@]-}"; then
      CLI_ERROR="Check cannot be both selected and excluded: $check_name"
      return 3
    fi
  done
  return 0
}

check_is_selected() {
  local check_name="$1"
  if (( ${#CLI_ONLY_CHECKS[@]} > 0 )) && ! array_contains "$check_name" "${CLI_ONLY_CHECKS[@]-}"; then
    return 1
  fi
  if array_contains "$check_name" "${CLI_EXCLUDED_CHECKS[@]-}"; then
    return 1
  fi
  return 0
}

run_audit() {
  reset_findings
  local check_name check_function
  for check_name in "${REGISTERED_CHECKS[@]}"; do
    check_is_selected "$check_name" || continue
    check_function="run_${check_name}_check"
    verbose_log "running check: $check_name"
    if declare -F "$check_function" >/dev/null 2>&1; then
      if ! "$check_function"; then
        add_finding "$check_name" info "Check incomplete" \
          "The $check_name check could not complete." \
          "Review verbose output and host permissions."
      fi
    else
      add_finding "$check_name" info "Check unavailable" \
        "The $check_name check is not available in this installation." \
        "Verify that all application modules are installed."
    fi
  done
}

print_check_list() {
  local index
  for ((index = 0; index < ${#REGISTERED_CHECKS[@]}; index += 1)); do
    printf '%-12s %s\n' "${REGISTERED_CHECKS[$index]}" "${CHECK_DESCRIPTIONS[$index]}"
  done
}
