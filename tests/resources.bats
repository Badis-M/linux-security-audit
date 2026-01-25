#!/usr/bin/env bats

setup() {
  source "$BATS_TEST_DIRNAME/../lib/common.sh"
  source "$BATS_TEST_DIRNAME/../lib/findings.sh"
  source "$BATS_TEST_DIRNAME/../lib/checks/resources.sh"
  reset_findings
}

@test "classifies filesystem thresholds" {
  fixture=$'Filesystem 1024-blocks Used Available Capacity Mounted on\n/dev/sda1 100 50 50 50% /\n/dev/sdb1 100 85 15 85% /data\n/dev/sdc1 100 95 5 95% /critical'

  report_filesystem_usage "$fixture" disk

  [ "$(count_findings_by_severity info)" -eq 1 ]
  [ "$(count_findings_by_severity warning)" -eq 1 ]
  [ "$(count_findings_by_severity critical)" -eq 1 ]
}

@test "classifies low available memory" {
  fixture=$'MemTotal: 100000 kB\nMemAvailable: 9000 kB\nSwapTotal: 10000 kB\nSwapFree: 1000 kB'

  report_memory_usage "$fixture"

  [ "${FINDING_SEVERITIES[0]}" = "critical" ]
  [ "${FINDING_SEVERITIES[1]}" = "critical" ]
}

@test "uses the legacy available-memory estimate" {
  fixture=$'MemTotal: 100000 kB\nMemFree: 10000 kB\nBuffers: 5000 kB\nCached: 10000 kB\nSwapTotal: 0 kB\nSwapFree: 0 kB'

  report_memory_usage "$fixture"

  [ "${FINDING_MESSAGES[0]}" = "Available memory is 25% of total memory." ]
  [ "${FINDING_TITLES[1]}" = "Swap unavailable" ]
}

@test "handles malformed resource data" {
  report_filesystem_usage "invalid" disk
  report_memory_usage "invalid"

  [ "$(count_findings_by_severity info)" -eq 2 ]
}
