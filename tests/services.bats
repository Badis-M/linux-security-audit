#!/usr/bin/env bats

setup() {
  source "$BATS_TEST_DIRNAME/../lib/common.sh"
  source "$BATS_TEST_DIRNAME/../lib/findings.sh"
  source "$BATS_TEST_DIRNAME/../lib/checks/services.sh"
  reset_findings
}

@test "reports an empty failed-unit list" {
  report_failed_units ""

  [ "${FINDING_SEVERITIES[0]}" = "info" ]
  [ "${FINDING_TITLES[0]}" = "No failed units" ]
}

@test "reports failed units as critical" {
  fixture=$'ssh.service loaded failed failed\nbackup.mount loaded failed failed'

  report_failed_units "$fixture"

  [ "${FINDING_SEVERITIES[0]}" = "critical" ]
  [[ "${FINDING_MESSAGES[0]}" == *"ssh.service"* ]]
  [[ "${FINDING_MESSAGES[0]}" == *"backup.mount"* ]]
}

@test "handles systemd absence in containers" {
  LSA_ROOT_DIR="$BATS_TEST_TMPDIR/root"

  run_services_check

  [ "${FINDING_SEVERITIES[0]}" = "info" ]
  [ "${FINDING_TITLES[0]}" = "systemd unavailable" ]
}
