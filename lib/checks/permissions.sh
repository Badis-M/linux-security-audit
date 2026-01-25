#!/usr/bin/env bash

permission_metadata_is_allowed() {
  local logical_path="$1"
  local mode="$2"
  local owner="$3"
  local group="$4"

  while [[ "$mode" == 0* && ${#mode} -gt 1 ]]; do
    mode="${mode#0}"
  done
  [[ "$owner" == "root" ]] || return 1
  case "$logical_path" in
    /etc/passwd|/etc/group)
      [[ "$group" == "root" ]] || return 1
      case "$mode" in 644|640|600) return 0 ;; esac
      ;;
    /etc/shadow|/etc/gshadow)
      [[ "$group" == "root" || "$group" == "shadow" ]] || return 1
      case "$mode" in 640|600|0) return 0 ;; esac
      ;;
  esac
  return 1
}

report_sensitive_file_metadata() {
  local logical_path="$1"
  local mode="$2"
  local owner="$3"
  local group="$4"

  if permission_metadata_is_allowed "$logical_path" "$mode" "$owner" "$group"; then
    add_finding permissions info "Protected file metadata" \
      "$logical_path has mode $mode and ownership $owner:$group."
  else
    add_finding permissions critical "Unsafe file metadata" \
      "$logical_path has unexpected mode $mode or ownership $owner:$group." \
      "Compare this metadata with the operating system defaults and restrict access."
  fi
}

run_permissions_check() {
  if ! command_exists stat; then
    add_finding permissions info "Permission metadata unavailable" \
      "The stat command is not available."
    return 0
  fi

  local logical_path host_path metadata mode owner group
  local sensitive_paths=(/etc/passwd /etc/shadow /etc/group /etc/gshadow)
  for logical_path in "${sensitive_paths[@]}"; do
    host_path="$(lsa_path "$logical_path")"
    if [[ ! -e "$host_path" ]]; then
      add_finding permissions info "Sensitive file absent" \
        "$logical_path is not present in this environment."
      continue
    fi

    if metadata="$(stat -Lc '%a|%U|%G' -- "$host_path" 2>/dev/null)"; then
      IFS='|' read -r mode owner group <<< "$metadata"
      report_sensitive_file_metadata "$logical_path" "$mode" "$owner" "$group"
    else
      add_finding permissions info "Permission metadata unavailable" \
        "Metadata for $logical_path could not be read." \
        "Review host permissions or inspect the file metadata manually."
    fi
  done
}
