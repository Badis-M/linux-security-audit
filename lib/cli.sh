#!/usr/bin/env bash

readonly LSA_VERSION="1.0.1"

reset_cli_options() {
  CLI_COMMAND=""
  CLI_FORMAT="text"
  CLI_OUTPUT=""
  CLI_MIN_SEVERITY="info"
  CLI_NO_COLOR=0
  CLI_VERBOSE=0
  CLI_SHOW_HELP=0
  CLI_ERROR=""
  CLI_ONLY_CHECKS=()
  CLI_EXCLUDED_CHECKS=()
}

set_cli_error() {
  CLI_ERROR="$1"
  return 3
}

parse_cli() {
  reset_cli_options

  if (( $# == 0 )); then
    set_cli_error "A command is required."
    return 3
  fi

  case "$1" in
    audit|list-checks|version)
      CLI_COMMAND="$1"
      shift
      ;;
    -h|--help)
      CLI_SHOW_HELP=1
      return 0
      ;;
    *)
      set_cli_error "Unknown command: $1"
      return 3
      ;;
  esac

  if [[ "$CLI_COMMAND" != "audit" ]]; then
    if (( $# == 1 )) && [[ "$1" == "-h" || "$1" == "--help" ]]; then
      CLI_SHOW_HELP=1
      return 0
    fi
    if (( $# > 0 )); then
      set_cli_error "The $CLI_COMMAND command does not accept options."
      return 3
    fi
    return 0
  fi

  while (( $# > 0 )); do
    case "$1" in
      --format|--output|--severity|--check|--exclude)
        if (( $# < 2 )) || [[ -z "$2" ]]; then
          set_cli_error "Missing value for $1."
          return 3
        fi
        case "$1" in
          --format) CLI_FORMAT="$2" ;;
          --output) CLI_OUTPUT="$2" ;;
          --severity) CLI_MIN_SEVERITY="$2" ;;
          --check) CLI_ONLY_CHECKS+=("$2") ;;
          --exclude) CLI_EXCLUDED_CHECKS+=("$2") ;;
        esac
        shift 2
        ;;
      --format=*|--output=*|--severity=*|--check=*|--exclude=*)
        local option="${1%%=*}"
        local value="${1#*=}"
        if [[ -z "$value" ]]; then
          set_cli_error "Missing value for $option."
          return 3
        fi
        case "$option" in
          --format) CLI_FORMAT="$value" ;;
          --output) CLI_OUTPUT="$value" ;;
          --severity) CLI_MIN_SEVERITY="$value" ;;
          --check) CLI_ONLY_CHECKS+=("$value") ;;
          --exclude) CLI_EXCLUDED_CHECKS+=("$value") ;;
        esac
        shift
        ;;
      --no-color)
        CLI_NO_COLOR=1
        shift
        ;;
      --verbose)
        CLI_VERBOSE=1
        shift
        ;;
      -h|--help)
        CLI_SHOW_HELP=1
        shift
        ;;
      --)
        shift
        if (( $# > 0 )); then
          set_cli_error "Unexpected positional argument: $1"
          return 3
        fi
        ;;
      -*)
        set_cli_error "Unknown option: $1"
        return 3
        ;;
      *)
        set_cli_error "Unexpected positional argument: $1"
        return 3
        ;;
    esac
  done

  case "$CLI_FORMAT" in
    text|json) ;;
    *)
      set_cli_error "Unsupported format: $CLI_FORMAT"
      return 3
      ;;
  esac

  case "$CLI_MIN_SEVERITY" in
    info|warning|critical) ;;
    *)
      set_cli_error "Unsupported severity: $CLI_MIN_SEVERITY"
      return 3
      ;;
  esac

  if (( CLI_NO_COLOR == 1 )) && [[ "$CLI_FORMAT" == "json" ]]; then
    CLI_NO_COLOR=1
  fi

  return 0
}

print_usage() {
  cat <<'EOF'
Usage:
  linux-security-audit audit [options]
  linux-security-audit list-checks
  linux-security-audit version

Audit options:
  --format text|json             Select the report format (default: text)
  --output PATH                  Write the report atomically to PATH
  --severity info|warning|critical
                                 Display findings at or above this severity
  --check NAME                   Run only this check (repeatable)
  --exclude NAME                 Exclude this check (repeatable)
  --no-color                     Disable ANSI colors
  --verbose                      Print execution details to stderr
  -h, --help                     Show this help
EOF
}
