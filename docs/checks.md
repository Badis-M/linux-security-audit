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
