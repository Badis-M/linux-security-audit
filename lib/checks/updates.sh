#!/usr/bin/env bash

distribution_is_debian_family() {
  local os_release="$1"
  local distribution_id distribution_like
  distribution_id="$(read_key_value_file "$os_release" ID || true)"
  distribution_like="$(read_key_value_file "$os_release" ID_LIKE || true)"
  [[ "$distribution_id" == "debian" || "$distribution_id" == "ubuntu" || " $distribution_like " == *" debian "* ]]
}

report_available_updates() {
  local apt_output="$1"
  local line update_count=0
  while IFS= read -r line; do
    [[ -n "$line" || "$line" == Listing* ]] || continue
    [[ "$line" == Listing* ]] && continue
    [[ "$line" == */* ]] || continue
    ((update_count += 1))
  done <<< "$apt_output"

  if (( update_count > 0 )); then
    add_finding updates warning "Package updates available" \
      "$update_count package update(s) are available according to local APT metadata, which may be stale." \
      "Review and apply updates through the host's normal change process."
  else
    add_finding updates info "No package updates reported" \
      "Local APT metadata reports no available package updates; the metadata may be stale."
  fi
}

run_updates_check() {
  local os_release
  os_release="$(lsa_path /etc/os-release)"
  if ! distribution_is_debian_family "$os_release"; then
    add_finding updates info "Update check unsupported" \
      "Package update inspection is only supported on Debian-family systems in version 1."
    return 0
  fi

  if ! command_exists apt; then
    add_finding updates info "APT metadata unavailable" \
      "The apt command is not available."
    return 0
  fi

  # Listing cached upgrades does not refresh package indexes or modify packages.
  if capture_command apt list --upgradable; then
    report_available_updates "$COMMAND_OUTPUT"
  else
    add_finding updates info "APT metadata unavailable" \
      "Available updates could not be queried from local APT metadata."
  fi
}
