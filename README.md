# Linux Security Audit

`linux-security-audit` is a read-only Bash CLI that inspects the security and
operational posture of Ubuntu and Debian hosts.

The project is under active development. Version 1 will provide modular host
checks, text and JSON reports, deterministic exit codes, Bats tests, and
ShellCheck validation.

## Safety

The audit never changes the inspected system and never prints sensitive file
contents. It is an operational aid, not a compliance certification.

## License

MIT
