#!/usr/bin/env bats

setup() {
  source "$BATS_TEST_DIRNAME/../lib/common.sh"
}

@test "detects available commands" {
  command_exists bash
  run command_exists command-that-must-not-exist-lsa
  [ "$status" -ne 0 ]
}

@test "validates unsigned integers" {
  is_unsigned_integer 0
  is_unsigned_integer 42
  run is_unsigned_integer -1
  [ "$status" -ne 0 ]
  run is_unsigned_integer 1.5
  [ "$status" -ne 0 ]
}

@test "sanitizes line breaks and tabs" {
  result="$(sanitize_text $'first\nsecond\tvalue\r')"

  [ "$result" = "first second value " ]
}

@test "finds exact array members" {
  array_contains ssh system ssh network
  run array_contains fire system ssh network
  [ "$status" -ne 0 ]
}

@test "joins values without a trailing separator" {
  result="$(join_by ', ' system ssh network)"

  [ "$result" = "system, ssh, network" ]
}

@test "prefixes host paths for fixtures" {
  LSA_ROOT_DIR="/tmp/fixture"

  [ "$(lsa_path /etc/os-release)" = "/tmp/fixture/etc/os-release" ]
}

@test "reads a quoted key from a key-value file" {
  fixture="$BATS_TEST_TMPDIR/os-release"
  printf 'NAME="Example Linux"\nID=example\n' > "$fixture"

  [ "$(read_key_value_file "$fixture" NAME)" = "Example Linux" ]
  [ "$(read_key_value_file "$fixture" ID)" = "example" ]
}

@test "captures successful command output" {
  capture_command printf '%s' 'safe output'

  [ "$COMMAND_STATUS" -eq 0 ]
  [ "$COMMAND_OUTPUT" = "safe output" ]
}

@test "preserves command failures" {
  run capture_command bash -c 'exit 7'

  [ "$status" -eq 7 ]
}
