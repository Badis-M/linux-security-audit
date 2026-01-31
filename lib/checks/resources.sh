#!/usr/bin/env bash

add_usage_finding() {
  local title_prefix="$1"
  local subject="$2"
  local percentage="$3"
  local severity="info"

  if (( percentage >= 90 )); then
    severity="critical"
  elif (( percentage >= 80 )); then
    severity="warning"
  fi

  add_finding resources "$severity" "$title_prefix usage" \
    "$subject usage is ${percentage}%." \
    "$([[ "$severity" == "info" ]] || printf 'Investigate capacity and reclaim or add resources.')"
}

report_filesystem_usage() {
  local filesystem_output="$1"
  local metric="$2"
  local _filesystem _total _used _available capacity mount_point
  local line_number=0 reported=0 percentage title_prefix

  while read -r _filesystem _total _used _available capacity mount_point; do
    ((line_number += 1))
    (( line_number == 1 )) && continue
    [[ -n "$capacity" && -n "$mount_point" ]] || continue
    percentage="${capacity%%%}"
    is_unsigned_integer "$percentage" || continue
    case "$metric" in
      disk) title_prefix="Disk" ;;
      inode) title_prefix="Inode" ;;
      *) return 3 ;;
    esac
    add_usage_finding "$title_prefix" "$(sanitize_text "$mount_point")" "$percentage"
    ((reported += 1))
  done <<< "$filesystem_output"

  if (( reported == 0 )); then
    add_finding resources info "Filesystem usage unavailable" \
      "No $metric usage records could be parsed."
  fi
}

report_memory_usage() {
  local meminfo="$1"
  local key value _
  local total=0 available=0 free=0 buffers=0 cached=0 swap_total=0 swap_free=0

  while read -r key value _; do
    case "$key" in
      MemTotal:) total="$value" ;;
      MemAvailable:) available="$value" ;;
      MemFree:) free="$value" ;;
      Buffers:) buffers="$value" ;;
      Cached:) cached="$value" ;;
      SwapTotal:) swap_total="$value" ;;
      SwapFree:) swap_free="$value" ;;
    esac
  done <<< "$meminfo"

  if ! is_unsigned_integer "$total" || (( total == 0 )); then
    add_finding resources info "Memory usage unavailable" \
      "Memory capacity could not be parsed from /proc/meminfo."
    return 0
  fi
  if ! is_unsigned_integer "$available" || (( available == 0 )); then
    available=$((free + buffers + cached))
  fi

  local available_percentage severity="info"
  available_percentage=$((available * 100 / total))
  if (( available_percentage < 10 )); then
    severity="critical"
  elif (( available_percentage < 20 )); then
    severity="warning"
  fi
  add_finding resources "$severity" "Available memory" \
    "Available memory is ${available_percentage}% of total memory." \
    "$([[ "$severity" == "info" ]] || printf 'Investigate memory pressure and the largest consumers.')"

  if is_unsigned_integer "$swap_total" && (( swap_total > 0 )); then
    local swap_used_percentage
    swap_used_percentage=$(((swap_total - swap_free) * 100 / swap_total))
    add_usage_finding "Swap" "Swap" "$swap_used_percentage"
  else
    add_finding resources info "Swap unavailable" \
      "No configured swap was reported."
  fi
}

run_resources_check() {
  if command_exists df; then
    if capture_command df -P; then
      report_filesystem_usage "$COMMAND_OUTPUT" disk
    else
      add_finding resources info "Disk usage unavailable" \
        "Filesystem capacity could not be queried."
    fi
    if capture_command df -Pi; then
      report_filesystem_usage "$COMMAND_OUTPUT" inode
    else
      add_finding resources info "Inode usage unavailable" \
        "Filesystem inode capacity could not be queried."
    fi
  else
    add_finding resources info "Filesystem usage unavailable" \
      "The df command is not available."
  fi

  local meminfo_file
  meminfo_file="$(lsa_path /proc/meminfo)"
  if [[ -r "$meminfo_file" ]]; then
    report_memory_usage "$(<"$meminfo_file")"
  else
    add_finding resources info "Memory usage unavailable" \
      "The /proc/meminfo interface is not available."
  fi
}
