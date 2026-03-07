# Security Policy

## Supported Scope

This repository is a workflow and automation template. Security reports are most useful when they involve:

- command injection or unsafe shell execution in maintained scripts
- unintended credential exposure in GitHub Actions or documented flows
- workflow behavior that can mutate repositories in an unsafe or surprising way
- documentation that instructs users to configure automation insecurely

## Reporting A Vulnerability

Preferred path:

1. Use GitHub private vulnerability reporting if it is enabled for this repository.
2. If private reporting is not available, open a minimal public issue requesting a private follow-up and do not include exploit details, secrets, or proof-of-concept payloads.

Please include:

- affected file or workflow
- impact
- reproduction steps
- any suggested mitigation

## Response Expectations

Best effort goals:

- acknowledge the report within 7 days
- confirm whether the issue is in scope
- provide a mitigation or resolution plan when the issue is valid

There is no guaranteed SLA. If the repository is unmaintained, downstream users should evaluate whether to fork and patch locally.
