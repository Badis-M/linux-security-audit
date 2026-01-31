#!/usr/bin/env bats

setup() {
  source "$BATS_TEST_DIRNAME/../lib/common.sh"
  source "$BATS_TEST_DIRNAME/../lib/cli.sh"
  source "$BATS_TEST_DIRNAME/../lib/findings.sh"
  source "$BATS_TEST_DIRNAME/../lib/audit.sh"
  reset_cli_options
}

@test "validates known checks" {
  CLI_ONLY_CHECKS=(system ssh)

  validate_check_selection
}

@test "rejects unknown checks" {
  CLI_ONLY_CHECKS=(unknown)

  if validate_check_selection; then
    false
  else
    status=$?
  fi

  [ "$status" -eq 3 ]
  [ "$CLI_ERROR" = "Unknown check: unknown" ]
}

@test "rejects contradictory check selection" {
  CLI_ONLY_CHECKS=(ssh)
  CLI_EXCLUDED_CHECKS=(ssh)

  if validate_check_selection; then
    false
  else
    status=$?
  fi

  [ "$status" -eq 3 ]
}

@test "runs only selected checks" {
  run_system_check() { add_finding system info "System" "System ran."; }
  run_ssh_check() { add_finding ssh warning "SSH" "SSH ran."; }
  CLI_ONLY_CHECKS=(system)

  run_audit

  [ "$(finding_count)" -eq 1 ]
  [ "${FINDING_CHECKS[0]}" = "system" ]
}
