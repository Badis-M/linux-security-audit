#!/usr/bin/env bash

format_uptime_seconds() {
  local total_seconds="$1"
  local days hours minutes
  days=$((total_seconds / 86400))
  hours=$(((total_seconds % 86400) / 3600))
  minutes=$(((total_seconds % 3600) / 60))
  printf '%sd %sh %sm' "$days" "$hours" "$minutes"
}

run_system_check() {
  local os_release pretty_name name version_id
  os_release="$(lsa_path /etc/os-release)"
  pretty_name=""

  if pretty_name="$(read_key_value_file "$os_release" PRETTY_NAME)"; then
    add_finding system info "Operating system" \
      "Detected $(sanitize_text "$pretty_name")."
  elif name="$(read_key_value_file "$os_release" NAME)"; then
    version_id="$(read_key_value_file "$os_release" VERSION_ID || true)"
    add_finding system info "Operating system" \
      "Detected $(sanitize_text "$name ${version_id:-unknown version}")."
  else
    add_finding system info "Operating system unavailable" \
      "The operating system release information could not be read."
  fi

  if command_exists uname; then
    local kernel architecture
    kernel="$(uname -r 2>/dev/null || printf 'unknown')"
    architecture="$(uname -m 2>/dev/null || printf 'unknown')"
    add_finding system info "Kernel" \
      "Kernel $(sanitize_text "$kernel") on $(sanitize_text "$architecture") architecture."
  else
    add_finding system info "Kernel unavailable" \
      "The uname command is not available."
  fi

  local uptime_file uptime_seconds
  uptime_file="$(lsa_path /proc/uptime)"
  if [[ -r "$uptime_file" ]] && read -r uptime_seconds _ < "$uptime_file"; then
    uptime_seconds="${uptime_seconds%%.*}"
    if is_unsigned_integer "$uptime_seconds"; then
      add_finding system info "Uptime" \
        "The host has been running for $(format_uptime_seconds "$uptime_seconds")."
    else
      add_finding system info "Uptime unavailable" \
        "Host uptime could not be parsed."
    fi
  else
    add_finding system info "Uptime unavailable" \
      "The /proc uptime interface is not available."
  fi

  if (( EUID == 0 )); then
    add_finding system info "Privilege level" \
      "The audit is running with privileged access."
  else
    add_finding system info "Privilege level" \
      "The audit is running without privileged access."
  fi
}
