# Validation and release procedure

Prepared version: `1.0.1`. No tag or release was created by the 2026-10-29 preparation.

## CI contract

Pull requests and pushes to `main` run `.github/workflows/ci.yml`. The same workflow is reusable by the manual release workflow, with the requested tag as its checkout reference.
Actions use verified immutable SHAs. Repository access is read-only during validation, checkout credentials are not persisted, and job timeouts are explicit.

The first remote attempt and its corrective follow-up are recorded in `VALIDATION.md`. A successful remote run of the corrected revision is still required before release. Branch protection rules are managed separately; a workflow file alone does not make checks mandatory for merging.

## Release authorization

1. Review the changes and validation results, commit and push only with the owner's authorization.
2. Choose the next version and check the changelog and version constants. Never move an existing tag.
3. With separate explicit authorization, create and push the matching stable `vX.Y.Z` tag on a commit reachable from `main`.
4. With explicit publication authorization, start the **Release** workflow manually and enter that existing tag. A normal push does not publish a release.
5. The reusable CI validates the selected revision and uploads its tested distributions. A failed check blocks publication.
6. The publication job verifies exact tag/HEAD identity, version agreement, main ancestry and checksums. It downloads the artifacts of this same run instead of rebuilding for publication.
7. Only the publication job receives `contents: write`; its `GH_TOKEN` is the ephemeral workflow token. No permanent token, PyPI account or deployment service is required.

`python3 scripts/check_release.py vX.Y.Z` is a read-only release check, requiring a full checkout with tags and `origin/main`. It intentionally rejects historical tags whose version differs from the current source.
GitHub environment approval rules may be added separately if the repository's plan supports them. The current manual dispatch requires an operator action; it is not a second-reviewer approval gate.

## Recovery and maintenance

If validation fails, fix the source and prepare a new reviewed revision. Do not bypass failing tests or replace a published tag. A failed publication can be investigated without rerunning destructive operations on personal resources.
Review pinned actions, image digests, dependency locks and security advisories when updating dependencies. A passing dependency audit means no known advisory was reported at that time, not proof of absence of vulnerabilities.

## Bash distribution

CI keeps Ubuntu 24.04 and Debian 13 in digest-pinned containers. Installing Bats, ShellCheck and Python modifies only these disposable containers. APT packages are not frozen to a repository snapshot; rebuilds of the validation environment can therefore change over time.

`make ci` checks syntax, ShellCheck, Bats and a synthetic smoke test. `make build` writes a deterministic `dist/linux-security-audit-VERSION.tar.gz` and `SHA256SUMS`. Only README, license, changelog, `bin/`, `lib/` and `docs/` enter the archive; local guides, reports and credentials are excluded by construction.

Both validation containers test extraction and the packaged CLI. The final packaging job also smoke-tests the exact archive uploaded. Keep the full extracted directory: copying only the executable loses its modules. Python, Bats and ShellCheck are development/build dependencies, not CLI runtime requirements.
