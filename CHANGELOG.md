# Changelog

All notable changes to this project are documented in this file.

## [Unreleased]

### Fixed

- Ignore systemctl summary lines when parsing failed units and disable the
  pager explicitly during service audits.

## [1.0.0] - 2026-02-02

### Added

- Read-only `audit`, `list-checks`, and `version` commands.
- Eight modular security and operational checks for Ubuntu and Debian.
- Deterministic text and JSON output with severity filtering.
- Atomic private report writes and stable exit codes.
- Bats fixtures, ShellCheck validation, smoke tests, and container CI.
- Architecture, check, exit-code, and security-model documentation.
