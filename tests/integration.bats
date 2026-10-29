#!/usr/bin/env bats

setup() {
  CLI="$BATS_TEST_DIRNAME/../bin/linux-security-audit"
  mkdir -p "$BATS_TEST_TMPDIR/bin"
  printf '#!/usr/bin/env bash\nprintf "fixture\\n"\n' > "$BATS_TEST_TMPDIR/bin/uname"
  chmod 700 "$BATS_TEST_TMPDIR/bin/uname"
  export PATH="$BATS_TEST_TMPDIR/bin:$PATH"
}

@test "prints the version" {
  run "$CLI" version

  [ "$status" -eq 0 ]
  [ "$output" = "linux-security-audit 1.0.1" ]
}

@test "lists every documented check" {
  run "$CLI" list-checks

  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 8 ]
  [[ "${lines[0]}" == system* ]]
  [[ "${lines[7]}" == updates* ]]
}

@test "returns 3 for invalid input" {
  run "$CLI" audit --format yaml

  [ "$status" -eq 3 ]
  [[ "$output" == *"Unsupported format: yaml"* ]]
}

@test "returns 3 for an unknown check" {
  run "$CLI" audit --check unknown

  [ "$status" -eq 3 ]
  [[ "$output" == *"Unknown check: unknown"* ]]
}

@test "runs a selected informational check end to end" {
  root="$BATS_TEST_TMPDIR/root"
  mkdir -p "$root/etc" "$root/proc"
  printf 'PRETTY_NAME="Fixture Linux"\n' > "$root/etc/os-release"
  printf '60.00 10.00\n' > "$root/proc/uptime"

  run env LSA_ROOT_DIR="$root" "$CLI" audit --check system --format json --no-color

  [ "$status" -eq 0 ]
  JSON_REPORT="$output" python3 -c 'import json, os; data=json.loads(os.environ["JSON_REPORT"]); assert len(data["findings"]) == 4'
}

@test "writes a private report file" {
  root="$BATS_TEST_TMPDIR/root"
  report="$BATS_TEST_TMPDIR/report.json"
  mkdir -p "$root/etc" "$root/proc"
  printf 'PRETTY_NAME="Fixture Linux"\n' > "$root/etc/os-release"
  printf '60.00 10.00\n' > "$root/proc/uptime"

  run env LSA_ROOT_DIR="$root" "$CLI" audit --check system --format json --output "$report"

  [ "$status" -eq 0 ]
  [ -f "$report" ]
  python3 - "$report" <<'CHECK'
import os, stat, sys
assert stat.S_IMODE(os.stat(sys.argv[1]).st_mode) == 0o600
CHECK
}
