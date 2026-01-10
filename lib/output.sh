#!/usr/bin/env bash

severity_label() {
  case "$1" in
    info) printf 'INFO' ;;
    warning) printf 'WARNING' ;;
    critical) printf 'CRITICAL' ;;
  esac
}

severity_color() {
  case "$1" in
    info) printf '\033[36m' ;;
    warning) printf '\033[33m' ;;
    critical) printf '\033[31m' ;;
  esac
}

render_text_report() {
  local use_color=0
  if (( CLI_NO_COLOR == 0 )) && [[ -t 1 ]]; then
    use_color=1
  fi

  printf 'Linux Security Audit\n'
  printf '====================\n\n'
  printf 'Summary: %s info, %s warning, %s critical\n\n' \
    "$(count_findings_by_severity info)" \
    "$(count_findings_by_severity warning)" \
    "$(count_findings_by_severity critical)"

  local index severity label visible_count=0 color reset
  for ((index = 0; index < ${#FINDING_CHECKS[@]}; index += 1)); do
    severity="${FINDING_SEVERITIES[$index]}"
    severity_is_visible "$severity" "$CLI_MIN_SEVERITY" || continue
    ((visible_count += 1))
    label="$(severity_label "$severity")"
    if (( use_color == 1 )); then
      color="$(severity_color "$severity")"
      reset=$'\033[0m'
      printf '%b[%s]%b %s: %s\n' "$color" "$label" "$reset" \
        "${FINDING_CHECKS[$index]}" "${FINDING_TITLES[$index]}"
    else
      printf '[%s] %s: %s\n' "$label" \
        "${FINDING_CHECKS[$index]}" "${FINDING_TITLES[$index]}"
    fi
    printf '  %s\n' "${FINDING_MESSAGES[$index]}"
    if [[ -n "${FINDING_RECOMMENDATIONS[$index]}" ]]; then
      printf '  Recommendation: %s\n' "${FINDING_RECOMMENDATIONS[$index]}"
    fi
    printf '\n'
  done

  if (( visible_count == 0 )); then
    printf 'No findings match the selected severity threshold.\n'
  fi
}

validate_output_path() {
  local output_path="$1"
  local output_directory

  if [[ -z "$output_path" || "$output_path" == */ ]]; then
    printf 'error: invalid output path\n' >&2
    return 3
  fi
  if [[ -L "$output_path" ]]; then
    printf 'error: output path must not be a symbolic link: %s\n' "$output_path" >&2
    return 3
  fi
  if [[ -e "$output_path" && ! -f "$output_path" ]]; then
    printf 'error: output path must be a regular file: %s\n' "$output_path" >&2
    return 3
  fi
  output_directory="$(dirname -- "$output_path")"
  if [[ ! -d "$output_directory" || ! -w "$output_directory" ]]; then
    printf 'error: output directory is not writable: %s\n' "$output_directory" >&2
    return 3
  fi
}

emit_report() {
  local renderer="$1"
  if [[ -z "$CLI_OUTPUT" ]]; then
    "$renderer"
    return 0
  fi

  validate_output_path "$CLI_OUTPUT" || return 3
  local output_directory temporary_file
  output_directory="$(dirname -- "$CLI_OUTPUT")"
  if ! temporary_file="$(mktemp "$output_directory/.linux-security-audit.XXXXXX")"; then
    printf 'error: could not create a temporary report file\n' >&2
    return 3
  fi
  chmod 600 "$temporary_file"

  if ! "$renderer" > "$temporary_file"; then
    rm -f -- "$temporary_file"
    printf 'error: could not render report\n' >&2
    return 3
  fi
  if ! mv -f -- "$temporary_file" "$CLI_OUTPUT"; then
    rm -f -- "$temporary_file"
    printf 'error: could not write report: %s\n' "$CLI_OUTPUT" >&2
    return 3
  fi
}
