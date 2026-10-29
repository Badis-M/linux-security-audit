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

@test "rejects control characters in output paths" {
  run validate_output_path $'report\nname.json'

  [ "$status" -eq 3 ]
}

@test "renders valid deterministic JSON" {
  add_finding system info 'Quoted "title"' 'Path C:\safe' "Review it."
  add_finding ssh warning "Password authentication" "Password login is enabled."

  first="$(render_json_report)"
  second="$(render_json_report)"

  [ "$first" = "$second" ]
  JSON_REPORT="$first" python3 -c 'import json, os; data=json.loads(os.environ["JSON_REPORT"]); assert data["summary"]["warning"] == 1; assert len(data["findings"]) == 2'
}

@test "applies severity filtering to JSON findings" {
  add_finding system info "System" "Detected."
  add_finding ssh critical "Root login" "Enabled."
  CLI_MIN_SEVERITY="critical"

  report="$(render_json_report)"

  JSON_REPORT="$report" python3 -c 'import json, os; data=json.loads(os.environ["JSON_REPORT"]); assert data["summary"]["info"] == 1; assert len(data["findings"]) == 1; assert data["findings"][0]["severity"] == "critical"'
}


@test "escapes every representable ASCII control character in JSON" {
  value="$(python3 -c 'print("".join(chr(i) for i in range(1, 32)), end="")')"
  escaped="$(json_escape "$value")"
  JSON_VALUE="\"$escaped\"" python3 -c 'import json, os; assert json.loads(os.environ["JSON_VALUE"]) == "".join(chr(i) for i in range(1, 32))'
}

@test "normalizes terminal controls before rendering findings" {
  add_finding resources info "Fixture" $'example\033[31m'
  report="$(render_json_report)"
  JSON_REPORT="$report" python3 -c 'import json, os; report=os.environ["JSON_REPORT"]; assert "\x1b" not in report; json.loads(report)'
}
