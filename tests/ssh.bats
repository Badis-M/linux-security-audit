#!/usr/bin/env bats

setup() {
  source "$BATS_TEST_DIRNAME/../lib/common.sh"
  source "$BATS_TEST_DIRNAME/../lib/findings.sh"
  source "$BATS_TEST_DIRNAME/../lib/checks/ssh.sh"
  reset_findings
}

@test "reports secure evaluated settings as information" {
  fixture=$'permitrootlogin no\npasswordauthentication no\npermitemptypasswords no\nmaxauthtries 3'

  report_sshd_configuration "$fixture"

  [ "$(finding_count)" -eq 4 ]
  [ "$(count_findings_by_severity info)" -eq 4 ]
}

@test "classifies dangerous authentication settings" {
  fixture=$'permitrootlogin yes\npasswordauthentication yes\npermitemptypasswords yes\nprotocol 1\nmaxauthtries 10'

  report_sshd_configuration "$fixture"

  [ "$(count_findings_by_severity critical)" -eq 3 ]
  [ "$(count_findings_by_severity warning)" -eq 2 ]
}

@test "accepts restricted root login policies" {
  fixture=$'permitrootlogin prohibit-password\npasswordauthentication no\npermitemptypasswords no\nmaxauthtries 6'

  report_sshd_configuration "$fixture"

  [ "${FINDING_TITLES[0]}" = "Root login restricted" ]
  [ "${FINDING_SEVERITIES[0]}" = "info" ]
}

@test "reports missing evaluated values without inventing failures" {
  report_sshd_configuration ""

  [ "$(count_findings_by_severity info)" -eq 4 ]
  [ "$(count_findings_by_severity warning)" -eq 0 ]
  [ "$(count_findings_by_severity critical)" -eq 0 ]
}
