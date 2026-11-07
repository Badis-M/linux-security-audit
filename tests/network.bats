#!/usr/bin/env bats

setup() {
  source "$BATS_TEST_DIRNAME/../lib/common.sh"
  source "$BATS_TEST_DIRNAME/../lib/findings.sh"
  source "$BATS_TEST_DIRNAME/../lib/checks/network.sh"
  reset_findings
  CLI_EXPECTED_TCP_PORTS=()
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

@test "expected TCP policy classifies network ports and preserves loopback and UDP" {
  CLI_EXPECTED_TCP_PORTS=(22)
  local endpoint
  for endpoint in '0.0.0.0:22' '0.0.0.0:8080' '[::]:8080' '127.0.0.1:8080' '[::1]:8080' '0.0.0.0:2222' ':::8080' '192.0.2.1:8080'; do
    report_listening_sockets "tcp LISTEN 0 128 $endpoint *:*"
  done
  [ "${FINDING_SEVERITIES[*]}" = "info warning warning info info warning warning warning" ]
  [ "${FINDING_TITLES[1]}" = "Unexpected TCP listening port" ]
  [ "${FINDING_TITLES[2]}" = "Unexpected TCP listening port" ]
  report_listening_sockets 'udp UNCONN 0 0 [::]:5353 [::]:*'
  [ "${FINDING_TITLES[8]}" = "Wildcard listening socket" ]
  [ "${FINDING_SEVERITIES[8]}" = warning ]
  report_listening_sockets 'udp UNCONN 0 0 127.0.0.1:5353 *:*'
  [ "${FINDING_SEVERITIES[9]}" = info ]
}

@test "expected ports accept numeric IPv6 and decimal port spellings" {
  CLI_EXPECTED_TCP_PORTS=(22)
  local endpoint
  for endpoint in '[::]:22' ':::22' '[2001:db8::1]:00022' '[0:0:0:0:0:0:0:1]:8080' '127.1.2.3:8080'; do
    report_listening_sockets "tcp LISTEN 0 128 $endpoint *:*"
  done
  [ "$(count_findings_by_severity info)" -eq 5 ]
}

@test "expected TCP wildcard port is informational" {
  CLI_EXPECTED_TCP_PORTS=(22)

  report_listening_sockets 'tcp LISTEN 0 128 *:22 *:*'

  [ "$(finding_count)" -eq 1 ]
  [ "${FINDING_SEVERITIES[0]}" = info ]
  [ "${FINDING_TITLES[0]}" = "Listening socket" ]
}

@test "unexpected TCP wildcard port produces a warning" {
  CLI_EXPECTED_TCP_PORTS=(22)

  report_listening_sockets 'tcp LISTEN 0 128 *:8080 *:*'

  [ "$(finding_count)" -eq 1 ]
  [ "${FINDING_SEVERITIES[0]}" = warning ]
  [ "${FINDING_TITLES[0]}" = "Unexpected TCP listening port" ]
}

@test "expected TCP policy rejects trailing IPv6 endpoint fields" {
  CLI_EXPECTED_TCP_PORTS=(22)

  report_listening_sockets 'tcp LISTEN 0 128 [::]:8080:22 *:*'

  [ "$(finding_count)" -eq 1 ]
  [ "${FINDING_SEVERITIES[0]}" = warning ]
  [ "${FINDING_TITLES[0]}" = "Unexpected TCP listening port" ]
}

@test "expected TCP policy rejects empty or repeated IPv6 zones" {
  CLI_EXPECTED_TCP_PORTS=(22)
  local endpoint
  for endpoint in '[::1%]:8080' '[fe80::1%eth0%junk]:22'; do
    reset_findings
    report_listening_sockets "tcp LISTEN 0 128 $endpoint *:*"
    [ "$(finding_count)" -eq 1 ]
    [ "${FINDING_SEVERITIES[0]}" = warning ]
    [ "${FINDING_TITLES[0]}" = "Unexpected TCP listening port" ]
  done
}

@test "expected TCP policy accepts named and numeric IPv6 zones" {
  CLI_EXPECTED_TCP_PORTS=(22)
  local endpoint
  for endpoint in '[fe80::1%eth0]:22' '[fe80::1%3]:22'; do
    reset_findings
    report_listening_sockets "tcp LISTEN 0 128 $endpoint *:*"
    [ "$(finding_count)" -eq 1 ]
    [ "${FINDING_SEVERITIES[0]}" = info ]
    [ "${FINDING_TITLES[0]}" = "Listening socket" ]
  done
}

@test "expected TCP policy accepts Linux interface names in both IPv6 scope forms" {
  CLI_EXPECTED_TCP_PORTS=(22)
  local endpoint
  for endpoint in '[fe80::1%eth+0]:22' '[fe80::1]%eth+0:22' '[fe80::1]%eth0:22' '[fe80::1]%3:22' '[fe80::1%eth@0]:22' '[fe80::1]%123456789012345:22'; do
    reset_findings
    report_listening_sockets "tcp LISTEN 0 128 $endpoint *:*"
    [ "$(finding_count)" -eq 1 ]
    [ "${FINDING_SEVERITIES[0]}" = info ]
    [ "${FINDING_TITLES[0]}" = "Listening socket" ]
  done
}

@test "unexpected TCP port with an external IPv6 scope produces a warning" {
  CLI_EXPECTED_TCP_PORTS=(22)

  report_listening_sockets 'tcp LISTEN 0 128 [fe80::1]%eth+0:8080 *:*'

  [ "$(finding_count)" -eq 1 ]
  [ "${FINDING_SEVERITIES[0]}" = warning ]
  [ "${FINDING_TITLES[0]}" = "Unexpected TCP listening port" ]
}

@test "expected TCP policy rejects invalid interface scopes and trailing port fields" {
  CLI_EXPECTED_TCP_PORTS=(22)
  local endpoint
  for endpoint in '[fe80::1]%:22' '[fe80::1]%eth0%junk:22' '[fe80::1%eth0]%eth0:22' '[fe80::1]%eth+0:8080:22' '[fe80::1%eth+0]:8080:22' '[fe80::1]%.:22' '[fe80::1]%..:22' '[fe80::1]%eth/0:22' '[fe80::1]%eth:0:22' '[fe80::1]%1234567890123456:22'; do
    reset_findings
    report_listening_sockets "tcp LISTEN 0 128 $endpoint *:*"
    [ "$(finding_count)" -eq 1 ]
    [ "${FINDING_SEVERITIES[0]}" = warning ]
    [ "${FINDING_TITLES[0]}" = "Unexpected TCP listening port" ]
  done
}

@test "interface scope validation rejects whitespace and counts bytes" {
  local zone
  for zone in '' . .. 'eth 0' $'eth\t0' $'eth\n0' 'eth/0' 'eth:0' 'eth%0' 'eth[0' 'eth]0' '1234567890123456' 'éééééééé'; do
    run network_zone_is_valid "$zone"
    [ "$status" -ne 0 ]
  done
  network_zone_is_valid 'eth+0'
  network_zone_is_valid '123456789012345'
}

@test "unreadable endpoints never match the expected TCP list" {
  CLI_EXPECTED_TCP_PORTS=(22)
  local endpoint
  for endpoint in 'garbage:22' '999.0.0.1:22' '[bad::address]:22' '[:::]:22' '[::1]:http' '0.0.0.0:0' '0.0.0.0:65536' '0.0.0.0:999999999999999999999' '0.0.0.0' '[::]:22junk'; do
    report_listening_sockets "tcp LISTEN 0 128 $endpoint *:*"
  done
  [ "$(count_findings_by_severity warning)" -eq 10 ]
}

@test "without expected ports specific network bindings retain their original classification" {
  report_listening_sockets $'tcp LISTEN 0 128 192.0.2.1:8080 *:*\ntcp LISTEN 0 128 [2001:db8::1]:8080 *:*'
  [ "${FINDING_SEVERITIES[*]}" = "info info" ]
  [ "${FINDING_TITLES[*]}" = "Listening socket Listening socket" ]
}

@test "reports an empty socket list" {
  report_listening_sockets ""

  [ "${FINDING_TITLES[0]}" = "No listening sockets" ]
  [ "${FINDING_SEVERITIES[0]}" = "info" ]
}
