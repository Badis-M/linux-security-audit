# Engineering Decisions

## Runtime dependencies

The application uses Bash rendering instead of requiring `jq` or Python. This
keeps runtime installation small; JSON escaping and validity are covered by
tests.

## Deterministic reports

Reports do not contain timestamps, host names, or current user names. Findings
are emitted in registry order so identical input produces identical output.

## Severity filtering

`--severity` controls presentation only. The process exit code always reflects
the highest severity detected across the complete selected audit.

## Unavailable data

Missing commands, container limitations, and permission failures normally
produce informational findings. They are not converted into security failures
without evidence of an unsafe state.

## Report writes

File reports use a mode `0600` temporary file in the destination directory and
an atomic rename. Symbolic links, special files, and paths containing control
characters are rejected.
