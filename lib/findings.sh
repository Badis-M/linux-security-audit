#!/usr/bin/env bash

reset_findings() {
  FINDING_CHECKS=()
  FINDING_SEVERITIES=()
  FINDING_TITLES=()
  FINDING_MESSAGES=()
  FINDING_RECOMMENDATIONS=()
}

severity_rank() {
  case "$1" in
    info) printf '0' ;;
    warning) printf '1' ;;
    critical) printf '2' ;;
    *) return 3 ;;
  esac
}

add_finding() {
  local check_name="$1"
  local severity="$2"
  local title="$3"
  local message="$4"
  local recommendation="${5:-}"

  if [[ -z "$check_name" || -z "$title" || -z "$message" ]]; then
    printf 'error: finding fields must not be empty\n' >&2
    return 3
  fi
  if ! severity_rank "$severity" >/dev/null; then
    printf 'error: invalid finding severity: %s\n' "$severity" >&2
    return 3
  fi

  FINDING_CHECKS+=("$(sanitize_text "$check_name")")
  FINDING_SEVERITIES+=("$severity")
  FINDING_TITLES+=("$(sanitize_text "$title")")
  FINDING_MESSAGES+=("$(sanitize_text "$message")")
  FINDING_RECOMMENDATIONS+=("$(sanitize_text "$recommendation")")
}

finding_count() {
  printf '%s' "${#FINDING_CHECKS[@]}"
}

count_findings_by_severity() {
  local requested="$1"
  local count=0
  local severity
  for severity in "${FINDING_SEVERITIES[@]}"; do
    if [[ "$severity" == "$requested" ]]; then
      ((count += 1))
    fi
  done
  printf '%s' "$count"
}

highest_finding_severity() {
  local highest="info"
  local severity
  for severity in "${FINDING_SEVERITIES[@]}"; do
    if (( $(severity_rank "$severity") > $(severity_rank "$highest") )); then
      highest="$severity"
    fi
  done
  printf '%s' "$highest"
}

finding_exit_code() {
  local highest
  highest="$(highest_finding_severity)"
  case "$highest" in
    info) printf '0' ;;
    warning) printf '1' ;;
    critical) printf '2' ;;
  esac
}

severity_is_visible() {
  local severity="$1"
  local minimum="$2"
  (( $(severity_rank "$severity") >= $(severity_rank "$minimum") ))
}
