#!/usr/bin/env bats

setup() {
  source "$BATS_TEST_DIRNAME/../lib/common.sh"
  source "$BATS_TEST_DIRNAME/../lib/findings.sh"
  source "$BATS_TEST_DIRNAME/../lib/checks/updates.sh"
  reset_findings
}

@test "detects Debian-family identifiers" {
  ubuntu="$BATS_TEST_TMPDIR/ubuntu-release"
  derivative="$BATS_TEST_TMPDIR/derivative-release"
  other="$BATS_TEST_TMPDIR/other-release"
  printf 'ID=ubuntu\n' > "$ubuntu"
  printf 'ID=example\nID_LIKE="debian ubuntu"\n' > "$derivative"
  printf 'ID=example\nID_LIKE="fedora"\n' > "$other"

  distribution_is_debian_family "$ubuntu"
  distribution_is_debian_family "$derivative"
  run distribution_is_debian_family "$other"
  [ "$status" -ne 0 ]
}

@test "counts cached package updates without package names" {
  fixture=$'Listing...\nopenssl/stable 1.2 amd64 [upgradable from: 1.1]\ncurl/stable 8.0 amd64 [upgradable from: 7.0]'

  report_available_updates "$fixture"

  [ "${FINDING_SEVERITIES[0]}" = "warning" ]
  [[ "${FINDING_MESSAGES[0]}" == "2 package update(s)"* ]]
  [[ "${FINDING_MESSAGES[0]}" != *"openssl"* ]]
}

@test "states that local metadata may be stale" {
  report_available_updates "Listing..."

  [ "${FINDING_SEVERITIES[0]}" = "info" ]
  [[ "${FINDING_MESSAGES[0]}" == *"may be stale"* ]]
}

@test "does not claim support for unrelated distributions" {
  LSA_ROOT_DIR="$BATS_TEST_TMPDIR/root"
  mkdir -p "$LSA_ROOT_DIR/etc"
  printf 'ID=fedora\n' > "$LSA_ROOT_DIR/etc/os-release"

  run_updates_check

  [ "${FINDING_TITLES[0]}" = "Update check unsupported" ]
  [ "${FINDING_SEVERITIES[0]}" = "info" ]
}
