# Rejected n8n assessment recipe

This directory is an investigation artifact, not an approved deployment image.
The supported npm installation was compared to official n8n using a shared Trivy
DB. Debian security updates reduce some OS findings but leave 11 critical and
170 high installed-package occurrences. Production Compose does not use it.
See ../../../docs/operations/n8n-security-2026-10-14.md for provenance, findings,
commands, limitations, and the release gate. Do not publish or promote it.
