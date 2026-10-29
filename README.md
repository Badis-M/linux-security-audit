# Linux Security Audit

[![CI](https://github.com/Badis-M/linux-security-audit/actions/workflows/ci.yml/badge.svg)](https://github.com/Badis-M/linux-security-audit/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

`linux-security-audit` is a read-only Bash CLI that inspects the security and
operational posture of Ubuntu and Debian hosts. It produces actionable text or
JSON findings without changing the audited system.

## Features

- Linux distribution, kernel, uptime, and privilege inventory
- failed systemd unit detection
- listening TCP/UDP sockets and wildcard binding visibility
- evaluated OpenSSH server settings through `sshd -T`
- UFW, firewalld, and nftables detection
- metadata checks for sensitive account database files
- disk, inode, memory, and swap thresholds
- cached Debian-family package update posture
- deterministic text and JSON reports
- predictable exit codes for automation

The tool does not claim that an open port is vulnerable and does not provide a
formal compliance certification.

## Requirements

- Bash
- Ubuntu or Debian for supported host auditing
- standard host tools such as `uname`, `df`, and `stat`

Commands such as `systemctl`, `ss`, `sshd`, `ufw`, `firewall-cmd`, `nft`, and
`apt` are optional. Missing commands produce explicit informational findings.

## Installation

Clone the repository and run the executable from the checkout:

```bash
git clone https://github.com/Badis-M/linux-security-audit.git
cd linux-security-audit
./bin/linux-security-audit version
```

The runtime does not require Bats, ShellCheck, Python, `jq`, or a cloud account.

## Usage

```text
linux-security-audit audit [options]
linux-security-audit list-checks
linux-security-audit version
```

Run a complete text audit:

```bash
./bin/linux-security-audit audit
```

Run selected checks and write a private JSON report atomically:

```bash
./bin/linux-security-audit audit \
  --check ssh \
  --check firewall \
  --format json \
  --output report.json
```

Display only critical findings while preserving the exit status derived from
all detected findings:

```bash
./bin/linux-security-audit audit --severity critical --no-color
```

Available options:

| Option | Description |
|---|---|
| `--format text\|json` | Select report format; default is `text` |
| `--output PATH` | Write the report atomically with mode `0600` |
| `--severity info\|warning\|critical` | Set the minimum displayed severity |
| `--check NAME` | Run only a named check; repeatable |
| `--exclude NAME` | Exclude a named check; repeatable |
| `--no-color` | Disable ANSI colors |
| `--verbose` | Print check execution details to standard error |

See the [sanitized text report](docs/examples/sample-report.txt) and
[sanitized JSON report](docs/examples/sample-report.json) for output examples.

## Checks

| Check | Scope |
|---|---|
| `system` | Distribution, kernel, architecture, uptime, and privilege level |
| `services` | Failed systemd units |
| `network` | Listening TCP/UDP sockets and wildcard bindings |
| `ssh` | Root login, password login, empty passwords, protocol, and attempt limit |
| `firewall` | UFW, firewalld, and nftables status |
| `permissions` | `/etc/passwd`, `/etc/shadow`, `/etc/group`, and `/etc/gshadow` metadata |
| `resources` | Disk, inode, memory, and swap thresholds |
| `updates` | Available updates using local APT metadata without refreshing indexes |

Detailed behavior is documented in [docs/checks.md](docs/checks.md).

## Exit codes

| Code | Meaning |
|---:|---|
| `0` | Audit completed with informational findings only |
| `1` | Audit completed with at least one warning |
| `2` | Audit completed with at least one critical finding |
| `3` | Invalid input or unrecoverable execution error |

Warnings and critical findings are normal audit results, not execution errors.

## Safety model

- No remediation command is executed.
- Package indexes are never refreshed automatically.
- Sensitive file contents and process details are never collected.
- User names and host names are excluded from system inventory.
- Report destinations that are symbolic links or special files are rejected.
- Reports can expose listening addresses and mount points and should be
  sanitized before publication.

See [docs/security-model.md](docs/security-model.md) for trust boundaries and
limitations.

## Development

Install Bats and ShellCheck, then run:

```bash
make ci
```

The target performs syntax validation, ShellCheck, 75 Bats tests, and smoke
tests. GitHub Actions repeats the suite in Ubuntu 24.04 and Debian 13
containers. The checkout action is pinned to an immutable commit SHA and the
workflow token has read-only repository permissions.

## Architecture

The executable loads independent modules for CLI parsing, findings, rendering,
orchestration, and host checks. Checks only add normalized findings; renderers
decide how those findings appear. See [docs/architecture.md](docs/architecture.md).

## Limitations

- Version 1 supports Ubuntu and Debian first.
- Container audits only observe the container namespace and do not represent
  the complete host.
- Local APT metadata may be stale.
- Heuristics must be interpreted in the context of the host's threat model.
- The project does not replace Lynis, OpenSCAP, CIS-CAT, or a professional
  security assessment.

## License

MIT © Badis Merakchi

## Agent context, validation and delivery

- Read [agent.md](agent.md) and the applicable repository instructions before making changes.
- [docs/VALIDATION.md](docs/VALIDATION.md) records dated results and remaining limits.
- [docs/RELEASE.md](docs/RELEASE.md) explains CI, artifact checks and explicitly authorized manual publication.
- The French `contexte.md` guide is local and ignored by Git; it is intentionally absent from clones and distributions.

A normal push to `main` runs CI but does not publish a release. Existing GitHub runs describe earlier commits and do not validate the current uncommitted changes.
