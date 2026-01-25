#!/usr/bin/env bats

setup() {
  source "$BATS_TEST_DIRNAME/../lib/common.sh"
  source "$BATS_TEST_DIRNAME/../lib/findings.sh"
  source "$BATS_TEST_DIRNAME/../lib/checks/permissions.sh"
  reset_findings
}

@test "accepts standard public account database metadata" {
  report_sensitive_file_metadata /etc/passwd 644 root root
  report_sensitive_file_metadata /etc/group 644 root root

  [ "$(count_findings_by_severity info)" -eq 2 ]
}

@test "accepts protected shadow metadata" {
  report_sensitive_file_metadata /etc/shadow 640 root shadow
  report_sensitive_file_metadata /etc/gshadow 600 root root

  [ "$(count_findings_by_severity info)" -eq 2 ]
}

@test "rejects broad or unexpected metadata" {
  report_sensitive_file_metadata /etc/shadow 644 root shadow
  report_sensitive_file_metadata /etc/passwd 644 service service

  [ "$(count_findings_by_severity critical)" -eq 2 ]
}

@test "never reads file contents when metadata is unavailable" {
  LSA_ROOT_DIR="$BATS_TEST_TMPDIR/root"
  mkdir -p "$LSA_ROOT_DIR/etc"

  run_permissions_check

  [ "$(finding_count)" -eq 4 ]
  [ "$(count_findings_by_severity info)" -eq 4 ]
}
