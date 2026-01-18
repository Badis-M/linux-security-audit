#!/usr/bin/env bats

setup() {
  source "$BATS_TEST_DIRNAME/../lib/common.sh"
  source "$BATS_TEST_DIRNAME/../lib/findings.sh"
  source "$BATS_TEST_DIRNAME/../lib/checks/firewall.sh"
  reset_findings
}

@test "reports an active firewall as information" {
  report_firewall_status 2 "UFW, nftables" "" ""

  [ "${FINDING_SEVERITIES[0]}" = "info" ]
  [ "${FINDING_TITLES[0]}" = "Firewall active" ]
}

@test "reports detected inactive tooling as a warning" {
  report_firewall_status 1 "" "UFW" ""

  [ "${FINDING_SEVERITIES[0]}" = "warning" ]
  [[ "${FINDING_MESSAGES[0]}" == *"UFW"* ]]
}

@test "does not treat unreadable status as inactive" {
  report_firewall_status 1 "" "" "nftables"

  [ "${FINDING_SEVERITIES[0]}" = "info" ]
  [ "${FINDING_TITLES[0]}" = "Firewall status unknown" ]
}

@test "warns when no supported firewall tool exists" {
  report_firewall_status 0 "" "" ""

  [ "${FINDING_SEVERITIES[0]}" = "warning" ]
  [ "${FINDING_TITLES[0]}" = "Firewall tooling unavailable" ]
}
