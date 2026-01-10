#!/usr/bin/env bats

setup() {
  source "$BATS_TEST_DIRNAME/../lib/common.sh"
  source "$BATS_TEST_DIRNAME/../lib/findings.sh"
  source "$BATS_TEST_DIRNAME/../lib/output.sh"
  reset_findings
  CLI_NO_COLOR=1
  CLI_MIN_SEVERITY="info"
  CLI_OUTPUT=""
}

@test "renders deterministic text output" {
  add_finding system info "Operating system" "Detected Example Linux."
  add_finding firewall warning "Firewall inactive" "No active firewall was detected." "Enable a host firewall."

  run render_text_report

  [ "$status" -eq 0 ]
  [[ "$output" == *"Summary: 1 info, 1 warning, 0 critical"* ]]
  [[ "$output" == *"[WARNING] firewall: Firewall inactive"* ]]
  [[ "$output" == *"Recommendation: Enable a host firewall."* ]]
}

@test "filters displayed findings but keeps the full summary" {
  add_finding system info "Operating system" "Detected Example Linux."
  add_finding ssh critical "Root login" "Root login is enabled."
  CLI_MIN_SEVERITY="critical"

  run render_text_report

  [[ "$output" == *"Summary: 1 info, 0 warning, 1 critical"* ]]
  [[ "$output" != *"Operating system"* ]]
  [[ "$output" == *"Root login"* ]]
}

@test "writes reports atomically with private permissions" {
  add_finding system info "Operating system" "Detected Example Linux."
  CLI_OUTPUT="$BATS_TEST_TMPDIR/report.txt"

  emit_report render_text_report

  [ -f "$CLI_OUTPUT" ]
  [ "$(stat -c '%a' "$CLI_OUTPUT" 2>/dev/null || stat -f '%Lp' "$CLI_OUTPUT")" = "600" ]
  grep -q "Linux Security Audit" "$CLI_OUTPUT"
}

@test "rejects symbolic-link output paths" {
  target="$BATS_TEST_TMPDIR/target"
  link="$BATS_TEST_TMPDIR/report"
  touch "$target"
  ln -s "$target" "$link"

  run validate_output_path "$link"

  [ "$status" -eq 3 ]
}
