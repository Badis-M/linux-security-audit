# Validation — 2026-10-29

Current status: the initial hardening was committed and pushed by the owner at `ace51a25c8cbe9083613f61c6f0e4309f8258c18`. The CI follow-up below records the failed first remote attempt and the locally checked correction; the initial preparation results remain historical.


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

## CI follow-up — 2026-10-29

- Remote evidence: [CI run](https://github.com/Badis-M/linux-security-audit/actions/runs/40832441596) at `ace51a25c8cbe9083613f61c6f0e4309f8258c18`; inspected read-only, without rerunning a workflow.
- Observed result: Les deux jobs de validation Ubuntu/Debian ont échoué au lint : leurs ShellCheck 0.9.0/0.10.0 émettent SC2317 pour les fonctions simulées appelées indirectement. Le job package a été ignoré après ces échecs.
- Correction: Les annotations ciblées des seules fonctions simulées couvrent maintenant SC2317 et SC2329. Aucun contrôle ShellCheck n’a été désactivé globalement et le code runtime n’a pas été changé.
- Local verification: Échec SC2317 reproduit avec ShellCheck 0.10 sur les anciens tests, puis disparition après correction. Lint réussi avec ShellCheck 0.10 et 0.11 ; make ci build réussi avec Bash 5.2.37, Bats 1.14.0 et ShellCheck 0.10 dans une copie temporaire macOS : 75 tests, smoke synthétique et construction de l’archive. ShellCheck 0.9 et les deux conteneurs Linux n’ont pas été exécutés localement.
- Scope: only CI command compatibility or test-linter annotations changed. Runtime behavior, package versions, lock files and release authorization remain unchanged.
- Pending: the corrected revision has not run on GitHub. No commit, push, tag, release or workflow dispatch was performed by the agent during this follow-up.
