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

## Expected TCP listening ports

By default, the network check keeps the wildcard classification above. To
supply an explicit list of expected TCP ports on network interfaces, use:

```bash
./bin/linux-security-audit audit --check network \
  --expected-tcp-port 22 --expected-tcp-port=443
```

The audit-only option is repeatable and accepts decimal ports from 1 to 65535
(including leading zeroes). Missing, nonnumeric, or out-of-range values are
invalid CLI arguments (exit code 3). Each port is compared as a whole number:
22 does not cover 2222.

With a list, valid non-loopback TCP endpoints are informational when their
port is listed; otherwise they produce an `Unexpected TCP listening port`
warning. Unreadable addresses or ports also produce that warning, never a
match. IPv4 loopback (127.0.0.0/8) and IPv6 loopback remain informational,
regardless of the list. UDP classification is unchanged.

These findings describe local listening sockets, not Internet reachability.
Routing, firewalls, and network namespaces require separate investigation.
