# Security Model

## Trust boundaries

The audited host, its command output, and CLI-supplied paths are treated as
untrusted input. Output is escaped for its destination format and is never
evaluated as shell code.

## Read-only guarantee

Version 1 only invokes commands that inspect local state. It does not refresh
package indexes, restart services, change firewall rules, modify permissions,
or write below system paths. The only optional write is the report path
explicitly supplied by the operator.

Reports are written through a temporary file in the destination directory and
then renamed into place. Symbolic-link destinations and non-regular existing
destinations are rejected.

## Sensitive information

The tool never reads or prints the contents of password databases, SSH private
keys, or authentication files. Permission checks inspect metadata only.
Process information is excluded from socket collection. The current user name
and host name are not included in reports.

Listening addresses and mount points may still reveal host topology. Operators
must sanitize generated reports before publishing them.

## Privileges

Root access is not required. Checks report unavailable data explicitly when
the current user lacks permission. Running as root may expose more complete
system metadata, but does not enable remediation behavior.

## Limitations

The checks use operational heuristics. A warning is not proof of a
vulnerability, and a clean report is not evidence of formal compliance.

## Output control characters and visibility

Representable ASCII controls are escaped in JSON; finding text normalizes control characters so host strings do not inject raw terminal escape sequences. NUL cannot be represented in a Bash variable. An unreadable or unexpected firewalld response is unknown, not proof of an inactive firewall. Only its explicit stopped response is classified as inactive.

Development smoke tests use a synthetic root and a fake `uname`. The CI installs validation dependencies only inside disposable containers. See `RELEASE.md` for distribution contents and publication conditions.
