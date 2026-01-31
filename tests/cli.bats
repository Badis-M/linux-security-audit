#!/usr/bin/env bats

setup() {
  source "$BATS_TEST_DIRNAME/../lib/cli.sh"
}

@test "requires a command" {
  if parse_cli; then
    false
  else
    status=$?
  fi

  [ "$status" -eq 3 ]
  [ "$CLI_ERROR" = "A command is required." ]
}

@test "parses default audit options" {
  parse_cli audit

  [ "$CLI_COMMAND" = "audit" ]
  [ "$CLI_FORMAT" = "text" ]
  [ "$CLI_MIN_SEVERITY" = "info" ]
  [ "${#CLI_ONLY_CHECKS[@]}" -eq 0 ]
}

@test "parses repeated selection options" {
  parse_cli audit --check system --check=ssh --exclude network

  [ "${CLI_ONLY_CHECKS[0]}" = "system" ]
  [ "${CLI_ONLY_CHECKS[1]}" = "ssh" ]
  [ "${CLI_EXCLUDED_CHECKS[0]}" = "network" ]
}

@test "parses output options" {
  parse_cli audit --format json --output report.json --severity warning --no-color --verbose

  [ "$CLI_FORMAT" = "json" ]
  [ "$CLI_OUTPUT" = "report.json" ]
  [ "$CLI_MIN_SEVERITY" = "warning" ]
  [ "$CLI_NO_COLOR" -eq 1 ]
  [ "$CLI_VERBOSE" -eq 1 ]
}

@test "rejects an unknown command" {
  if parse_cli scan; then
    false
  else
    status=$?
  fi

  [ "$status" -eq 3 ]
  [ "$CLI_ERROR" = "Unknown command: scan" ]
}

@test "rejects an unknown option" {
  if parse_cli audit --unsafe; then
    false
  else
    status=$?
  fi

  [ "$status" -eq 3 ]
  [ "$CLI_ERROR" = "Unknown option: --unsafe" ]
}

@test "rejects unsupported formats" {
  if parse_cli audit --format yaml; then
    false
  else
    status=$?
  fi

  [ "$status" -eq 3 ]
  [ "$CLI_ERROR" = "Unsupported format: yaml" ]
}

@test "rejects unsupported severities" {
  if parse_cli audit --severity emergency; then
    false
  else
    status=$?
  fi

  [ "$status" -eq 3 ]
  [ "$CLI_ERROR" = "Unsupported severity: emergency" ]
}

@test "rejects a missing option value" {
  if parse_cli audit --output; then
    false
  else
    status=$?
  fi

  [ "$status" -eq 3 ]
  [ "$CLI_ERROR" = "Missing value for --output." ]
}

@test "rejects options for version" {
  if parse_cli version --verbose; then
    false
  else
    status=$?
  fi

  [ "$status" -eq 3 ]
  [ "$CLI_ERROR" = "The version command does not accept options." ]
}
