# Checks

Version 1 defines the following checks in a stable order:

| Name | Purpose |
|---|---|
| `system` | Distribution, kernel, architecture, uptime, and privilege level |
| `services` | Failed systemd units when systemd is available |
| `network` | Listening TCP/UDP sockets and wildcard bindings |
| `ssh` | Evaluated OpenSSH server security settings |
| `firewall` | UFW, firewalld, or nftables status |
| `permissions` | Metadata for sensitive account database files |
| `resources` | Disk, inode, memory, and swap health |
| `updates` | Available Debian-family package updates using local metadata |

Unavailable commands or inaccessible subsystems produce an informational
finding unless the absence itself represents a material security condition.

## Default classification rules

- Failed systemd units are critical.
- Wildcard socket bindings are warnings; other listening sockets are
  informational.
- Direct SSH root login, empty-password authentication, and SSH protocol 1 are
  critical. Password authentication and `MaxAuthTries` above 6 are warnings.
- Missing firewall tooling or detected inactive tooling is a warning. An
  unreadable firewall state remains informational.
- Unexpected sensitive-file mode or ownership is critical.
- Disk, inode, and swap use at 80% is warning and at 90% is critical.
- Available memory below 20% is warning and below 10% is critical.
- Cached available package updates are warnings, with an explicit stale
  metadata qualification.

These thresholds are operational defaults, not compliance assertions.
