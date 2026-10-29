# Validation — 2026-10-29

Prepared version: `1.0.1`. Starting commit: `1c0874192bf7fd1ba4d0840bb07a7fbc9e289b14` plus the uncommitted hardening changes. Tests ran from temporary copies of the source on macOS arm64; the original project environments and personal Docker daemon were not modified.

| Check | Actual result |
| --- | --- |
| Environment | Bash macOS 3.2, Bats 1.14.0, ShellCheck 0.11.0 |
| Quality gates | 75 tests Bats ; syntaxe, ShellCheck et smoke synthétique réussis |
| Focused regressions | Caractères ASCII de contrôle, normalisation terminal, état firewalld inaccessible/inactif et CLI sur racine synthétique |
| Archive | Versioned archive built, extracted CLI smoke-tested on a synthetic root; repeated builds produced identical archive bytes in the tested environment. |
| Runtime boundary | No real system audit, package refresh, system change or personal data collection was performed. |
| Workflows | Six workflow files across the three projects validated locally with actionlint 1.7.12; no remote run was triggered. |

## Remaining limits

Local success is not evidence of a new GitHub run. Ubuntu/Debian execution of this iteration remains pending. Docker integration tests are prepared for a dedicated disposable runner and were not executed against the owner's daemon. Real systemd/SSH/firewall behavior, concurrent Docker state changes, exhaustive vulnerability coverage and release publication are not established by these results.

The new package versions are prepared locally, not published. No Git staging, commit, push, tag or release was performed. Historical results remain historical in the existing project documents and Obsidian notes.
