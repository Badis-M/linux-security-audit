#!/usr/bin/env bats

setup() {
  source "$BATS_TEST_DIRNAME/../lib/common.sh"
  source "$BATS_TEST_DIRNAME/../lib/findings.sh"
  source "$BATS_TEST_DIRNAME/../lib/checks/network.sh"
  reset_findings
}

@test "identifies IPv4 and IPv6 wildcard bindings" {
  socket_is_wildcard "0.0.0.0:22"
  socket_is_wildcard "[::]:443"
  socket_is_wildcard ":::8080"
  run socket_is_wildcard "127.0.0.1:5432"
  [ "$status" -ne 0 ]
}

@test "classifies wildcard sockets without calling them vulnerabilities" {
  fixture=$'tcp LISTEN 0 4096 0.0.0.0:22 0.0.0.0:*\ntcp LISTEN 0 128 127.0.0.1:5432 0.0.0.0:*\nudp UNCONN 0 0 [::]:5353 [::]:*'

  report_listening_sockets "$fixture"

  [ "$(finding_count)" -eq 3 ]
  [ "$(count_findings_by_severity warning)" -eq 2 ]
  [ "${FINDING_SEVERITIES[1]}" = "info" ]
  [[ "${FINDING_MESSAGES[*]}" != *"vulnerable"* ]]
}

@test "reports an empty socket list" {
  report_listening_sockets ""

  [ "${FINDING_TITLES[0]}" = "No listening sockets" ]
  [ "${FINDING_SEVERITIES[0]}" = "info" ]
}
