#!/usr/bin/env bats

setup() {
  source "$BATS_TEST_DIRNAME/../lib/cli.sh"
}

@test "requires a command" {
  run parse_cli

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
  run parse_cli scan

  [ "$status" -eq 3 ]
  [ "$CLI_ERROR" = "Unknown command: scan" ]
}

@test "rejects an unknown option" {
  run parse_cli audit --unsafe

  [ "$status" -eq 3 ]
  [ "$CLI_ERROR" = "Unknown option: --unsafe" ]
}

@test "rejects unsupported formats" {
  run parse_cli audit --format yaml

  [ "$status" -eq 3 ]
  [ "$CLI_ERROR" = "Unsupported format: yaml" ]
}

@test "rejects unsupported severities" {
  run parse_cli audit --severity emergency

  [ "$status" -eq 3 ]
  [ "$CLI_ERROR" = "Unsupported severity: emergency" ]
}

@test "rejects a missing option value" {
  run parse_cli audit --output

  [ "$status" -eq 3 ]
  [ "$CLI_ERROR" = "Missing value for --output." ]
}

@test "rejects options for version" {
  run parse_cli version --verbose

  [ "$status" -eq 3 ]
  [ "$CLI_ERROR" = "The version command does not accept options." ]
}
