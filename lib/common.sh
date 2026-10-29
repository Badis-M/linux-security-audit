#!/usr/bin/env bash

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

is_unsigned_integer() {
  [[ "$1" =~ ^[0-9]+$ ]]
}

sanitize_text() {
  local value="$1"
  value="${value//$'\r'/ }"
  value="${value//$'\n'/ }"
  value="${value//$'\t'/ }"
  local code character
  for ((code = 1; code < 32; code += 1)); do
    printf -v character '%b' "\\$(printf '%03o' "$code")"
    value="${value//"$character"/ }"
  done
  printf '%s' "$value"
}

array_contains() {
  local needle="$1"
  shift
  local item
  for item in "$@"; do
    if [[ "$item" == "$needle" ]]; then
      return 0
    fi
  done
  return 1
}

join_by() {
  local delimiter="$1"
  shift
  local result=""
  local item
  for item in "$@"; do
    if [[ -n "$result" ]]; then
      result+="$delimiter"
    fi
    result+="$item"
  done
  printf '%s' "$result"
}

lsa_path() {
  local path="$1"
  local root="${LSA_ROOT_DIR:-/}"
  if [[ "$root" == "/" ]]; then
    printf '%s' "$path"
  else
    printf '%s%s' "${root%/}" "$path"
  fi
}

capture_command() {
  COMMAND_OUTPUT=""
  COMMAND_STATUS=0
  if COMMAND_OUTPUT="$("$@" 2>/dev/null)"; then
    return 0
  else
    COMMAND_STATUS=$?
    return "$COMMAND_STATUS"
  fi
}

verbose_log() {
  if [[ "${CLI_VERBOSE:-0}" -eq 1 ]]; then
    printf 'debug: %s\n' "$1" >&2
  fi
}

read_key_value_file() {
  local file="$1"
  local requested_key="$2"
  local key value

  [[ -r "$file" ]] || return 1
  while IFS='=' read -r key value; do
    if [[ "$key" == "$requested_key" ]]; then
      value="${value#\"}"
      value="${value%\"}"
      printf '%s' "$value"
      return 0
    fi
  done < "$file"
  return 1
}
