#!/usr/bin/env bats

setup() {
  source "$BATS_TEST_DIRNAME/../lib/common.sh"
  source "$BATS_TEST_DIRNAME/../lib/findings.sh"
  source "$BATS_TEST_DIRNAME/../lib/checks/services.sh"
  reset_findings
}

@test "reports an empty failed-unit list" {
  report_failed_units "0 loaded units listed."

  [ "${FINDING_SEVERITIES[0]}" = "info" ]
  [ "${FINDING_TITLES[0]}" = "No failed units" ]
}

@test "reports failed units as critical and ignores summary lines" {
  fixture=$'  ● ssh.service loaded failed failed\nbackup.mount loaded failed failed\n2 loaded units listed.'

  report_failed_units "$fixture"

  [ "$(finding_count)" -eq 1 ]
  [ "${FINDING_SEVERITIES[0]}" = "critical" ]
  [[ "${FINDING_MESSAGES[0]}" == "2 failed unit(s):"* ]]
  [[ "${FINDING_MESSAGES[0]}" == *"ssh.service"* ]]
  [[ "${FINDING_MESSAGES[0]}" == *"backup.mount"* ]]
  [[ "${FINDING_MESSAGES[0]}" != *"loaded units listed"* ]]
}

@test "handles systemd absence in containers" {
  LSA_ROOT_DIR="$BATS_TEST_TMPDIR/root"

  run_services_check

  [ "${FINDING_SEVERITIES[0]}" = "info" ]
  [ "${FINDING_TITLES[0]}" = "systemd unavailable" ]
}
