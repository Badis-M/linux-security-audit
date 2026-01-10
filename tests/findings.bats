#!/usr/bin/env bats

setup() {
  source "$BATS_TEST_DIRNAME/../lib/common.sh"
  source "$BATS_TEST_DIRNAME/../lib/findings.sh"
  reset_findings
}

@test "adds a normalized finding" {
  add_finding ssh warning "Password login" $'Password\nauthentication is enabled.' "Disable it."

  [ "$(finding_count)" -eq 1 ]
  [ "${FINDING_CHECKS[0]}" = "ssh" ]
  [ "${FINDING_MESSAGES[0]}" = "Password authentication is enabled." ]
}

@test "rejects invalid severities" {
  run add_finding ssh emergency "Invalid" "Invalid severity"

  [ "$status" -eq 3 ]
  [ "$(finding_count)" -eq 0 ]
}

@test "counts findings by severity" {
  add_finding system info "System" "Detected system."
  add_finding ssh warning "SSH" "Review SSH."
  add_finding firewall warning "Firewall" "Review firewall."

  [ "$(count_findings_by_severity info)" -eq 1 ]
  [ "$(count_findings_by_severity warning)" -eq 2 ]
  [ "$(count_findings_by_severity critical)" -eq 0 ]
}

@test "maps highest severity to exit code" {
  add_finding system info "System" "Detected system."
  [ "$(finding_exit_code)" -eq 0 ]

  add_finding firewall warning "Firewall" "Firewall is inactive."
  [ "$(finding_exit_code)" -eq 1 ]

  add_finding permissions critical "Permissions" "Sensitive file is exposed."
  [ "$(finding_exit_code)" -eq 2 ]
}

@test "filters severities by minimum rank" {
  severity_is_visible warning info
  severity_is_visible warning warning
  ! severity_is_visible warning critical
}
