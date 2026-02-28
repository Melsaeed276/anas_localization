# Security Policy

## Supported Versions

Security fixes are applied to the latest active branch and included in the next release.

## Reporting a Vulnerability

Please do **not** open a public GitHub issue for sensitive vulnerabilities.

Instead:

1. Open a private security advisory in the repository, or
2. Contact the maintainer directly with:
   - impact summary
   - affected versions
   - proof of concept or reproduction steps
   - suggested mitigation if available

## Triage Process

- Acknowledgement target: 72 hours.
- Initial severity assessment: 7 days.
- Fix timeline depends on severity and exploitability.

## Scope Notes

Security reports are most useful when they involve:

- translation file parsing behavior
- CLI import/export handling for untrusted content
- runtime locale loading from remote sources
- dependency or supply-chain risk in release pipeline
