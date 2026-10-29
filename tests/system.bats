#!/usr/bin/env bats

setup() {
  source "$BATS_TEST_DIRNAME/../lib/common.sh"
  source "$BATS_TEST_DIRNAME/../lib/findings.sh"
  source "$BATS_TEST_DIRNAME/../lib/checks/system.sh"
  # Called indirectly by the sourced collector.
  # shellcheck disable=SC2329
  uname() { printf 'fixture\n'; }
  reset_findings
  LSA_ROOT_DIR="$BATS_TEST_TMPDIR/root"
  mkdir -p "$LSA_ROOT_DIR/etc" "$LSA_ROOT_DIR/proc"
}

@test "formats uptime without host identity" {
  printf 'PRETTY_NAME="Example Linux 1"\n' > "$LSA_ROOT_DIR/etc/os-release"
  printf '183845.00 100.00\n' > "$LSA_ROOT_DIR/proc/uptime"

  run_system_check

  [ "$(finding_count)" -eq 4 ]
  [ "${FINDING_MESSAGES[0]}" = "Detected Example Linux 1." ]
  [ "${FINDING_MESSAGES[2]}" = "The host has been running for 2d 3h 4m." ]
  [[ "${FINDING_MESSAGES[*]}" != *"$(hostname)"* ]]
  [[ "${FINDING_MESSAGES[*]}" != *"$(id -un)"* ]]
}

@test "reports missing inventory sources as information" {
  run_system_check

  [ "${FINDING_SEVERITIES[0]}" = "info" ]
  [ "${FINDING_TITLES[0]}" = "Operating system unavailable" ]
  [ "${FINDING_TITLES[2]}" = "Uptime unavailable" ]
}

@test "formats uptime boundaries" {
  [ "$(format_uptime_seconds 0)" = "0d 0h 0m" ]
  [ "$(format_uptime_seconds 90061)" = "1d 1h 1m" ]
}
