# Changelog

All notable changes to this project are documented in this file.

## [Unreleased]

## [1.0.1] - 2026-10-29

### Fixed

- Ignore systemctl summary lines when parsing failed units and disable the
  pager explicitly during service audits.

- Escape all representable ASCII control characters in JSON and normalize terminal controls in findings.
- Preserve unknown firewalld status on permission/transport errors.

### Added

- Synthetic smoke tests, deterministic versioned archives, checksum and extraction checks.
- Manual release workflow gated by the reusable Ubuntu/Debian CI.
- Agent instructions and a separately ignored French local guide.

Version 1.0.1 is prepared locally; no release is implied by this changelog entry.

## [1.0.0] - 2026-02-02

### Added

- Read-only `audit`, `list-checks`, and `version` commands.
- Eight modular security and operational checks for Ubuntu and Debian.
- Deterministic text and JSON output with severity filtering.
- Atomic private report writes and stable exit codes.
- Bats fixtures, ShellCheck validation, smoke tests, and container CI.
- Architecture, check, exit-code, and security-model documentation.
