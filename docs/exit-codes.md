# Exit Codes

| Code | Meaning |
|---:|---|
| `0` | Audit completed with informational findings only |
| `1` | Audit completed with at least one warning |
| `2` | Audit completed with at least one critical finding |
| `3` | Invalid input or unrecoverable execution error |

Output filtering does not alter the exit code. For example, an audit containing
a critical finding still exits with `2` when `--severity critical` is used.
