#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fixture_dir="$(mktemp -d)"
trap 'rm -rf "$fixture_dir"' EXIT
mkdir -p "$fixture_dir/root/etc" "$fixture_dir/root/proc" "$fixture_dir/bin"
printf 'PRETTY_NAME="Fixture Linux"\n' > "$fixture_dir/root/etc/os-release"
printf '60.00 10.00\n' > "$fixture_dir/root/proc/uptime"
printf '#!/usr/bin/env bash\nprintf "fixture\\n"\n' > "$fixture_dir/bin/uname"
chmod 700 "$fixture_dir/bin/uname"
"$project_dir/bin/linux-security-audit" version
"$project_dir/bin/linux-security-audit" list-checks > /dev/null
PATH="$fixture_dir/bin:$PATH" LSA_ROOT_DIR="$fixture_dir/root" \
  "$project_dir/bin/linux-security-audit" audit --check system --format json --no-color > "$fixture_dir/report.json"
python3 - "$fixture_dir/report.json" <<'CHECK'
import json, sys
from pathlib import Path
report = json.loads(Path(sys.argv[1]).read_text())
assert len(report["findings"]) == 4
assert report["summary"] == {"info": 4, "warning": 0, "critical": 0}
assert any(item["message"] == "Detected Fixture Linux." for item in report["findings"])
CHECK

status=0
PATH="$fixture_dir/bin:$PATH" LSA_ROOT_DIR="$fixture_dir/does-not-exist" \
  "$project_dir/bin/linux-security-audit" audit --check system \
    --output "$fixture_dir/missing/report.json" > "$fixture_dir/stdout" 2> "$fixture_dir/stderr" || status=$?
[[ "$status" -eq 3 ]]
[[ ! -s "$fixture_dir/stdout" ]]
grep -q '^error: output directory is not writable:' "$fixture_dir/stderr"

status=0
"$project_dir/bin/linux-security-audit" audit \
  --exclude system --exclude services --exclude network --exclude ssh \
  --exclude firewall --exclude permissions --exclude resources --exclude updates \
  > "$fixture_dir/stdout" 2> "$fixture_dir/stderr" || status=$?
[[ "$status" -eq 3 ]]
[[ ! -s "$fixture_dir/stdout" ]]
grep -q '^error: At least one check must be selected' "$fixture_dir/stderr"

printf 'PRETTY_NAME="Fixture without newline"' > "$fixture_dir/root/etc/os-release"
PATH="$fixture_dir/bin:$PATH" LSA_ROOT_DIR="$fixture_dir/root" \
  "$project_dir/bin/linux-security-audit" audit --check system > "$fixture_dir/text"
grep -q 'Detected Fixture without newline' "$fixture_dir/text"

printf '0008.00 0.00\n' > "$fixture_dir/root/proc/uptime"
PATH="$fixture_dir/bin:$PATH" LSA_ROOT_DIR="$fixture_dir/root" \
  "$project_dir/bin/linux-security-audit" audit --check system > "$fixture_dir/text"
grep -q '0d 0h 0m' "$fixture_dir/text"

printf '#!/usr/bin/env bash\nprintf "unexpected diagnostic with extra words here\\n"\n' > "$fixture_dir/bin/ss"
chmod 700 "$fixture_dir/bin/ss"
PATH="$fixture_dir/bin:$PATH" "$project_dir/bin/linux-security-audit" audit --check network > "$fixture_dir/text"
grep -q 'No listening TCP or UDP sockets' "$fixture_dir/text"
