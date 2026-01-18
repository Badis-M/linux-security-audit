#!/usr/bin/env bash

report_failed_units() {
  local systemctl_output="$1"
  local line unit
  local failed_units=()

  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    if [[ "$line" == "● "* ]]; then
      line="${line#● }"
    fi
    read -r unit _ <<< "$line"
    [[ -n "$unit" ]] && failed_units+=("$(sanitize_text "$unit")")
  done <<< "$systemctl_output"

  if (( ${#failed_units[@]} == 0 )); then
    add_finding services info "No failed units" \
      "systemd reports no failed units."
  else
    add_finding services critical "Failed systemd units" \
      "${#failed_units[@]} failed unit(s): $(join_by ', ' "${failed_units[@]}")." \
      "Inspect the failed units with systemctl status and journalctl."
  fi
}

run_services_check() {
  local systemd_directory
  systemd_directory="$(lsa_path /run/systemd/system)"

  if ! command_exists systemctl || [[ ! -d "$systemd_directory" ]]; then
    add_finding services info "systemd unavailable" \
      "systemd is not active or systemctl is unavailable in this environment."
    return 0
  fi

  if capture_command systemctl --failed --no-legend --plain; then
    report_failed_units "$COMMAND_OUTPUT"
  else
    add_finding services info "Service status unavailable" \
      "Failed systemd units could not be queried." \
      "Review host permissions or run the audit in the host namespace."
  fi
}
