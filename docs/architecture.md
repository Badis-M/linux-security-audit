# Architecture

## Overview

The executable in `bin/` loads small Bash modules from `lib/`. CLI parsing,
audit orchestration, finding storage, rendering, and host checks remain
separate so each concern can be tested independently.

```text
bin/linux-security-audit
        |
        +-- lib/cli.sh
        +-- lib/audit.sh
        +-- lib/findings.sh
        +-- lib/output.sh
        +-- lib/checks/*.sh
```

Checks communicate with the rest of the application only by adding findings.
They do not write reports directly and do not decide the process exit code.
This keeps text and JSON output consistent.

## Finding model

Each finding has five fields:

- check name;
- severity (`info`, `warning`, or `critical`);
- short title;
- factual message;
- optional recommendation.

Findings are emitted in a stable check order. The highest detected severity
determines the audit exit code, even if display filtering hides that finding.

## Portability

Ubuntu and Debian are the supported targets. The code avoids associative
arrays so its non-host-specific modules can also run with the Bash 3.2 version
shipped by macOS. Host checks may rely on Linux interfaces such as `/proc` and
must return an informational finding when those interfaces are unavailable.

## Dependency policy

The runtime has no mandatory dependency beyond Bash and standard Linux tools.
Optional commands are detected before use. Their absence must never cause a
silent or partial success.
