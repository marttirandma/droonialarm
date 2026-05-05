# Security Policy

## Reporting a vulnerability

If you discover a security vulnerability in Droonialarm, please report it via:

- **E-mail:** randma.martti@gmail.com (PGP key on request)
- **Subject line:** `[SECURITY] Droonialarm: <short description>`

Please **do not** open a public GitHub issue for security vulnerabilities.

We aim to respond within 72 hours and to publish a fix within 14 days for high-severity issues.

## Scope

Security issues we are interested in:

- Authentication/authorization bypass in the backend
- Injection vulnerabilities (SQL, command, path) in the logger or backend
- Cross-tenant data leakage between users
- Push notification spoofing or hijack
- Privilege escalation in the Android NotificationListenerService relay
- Privacy regressions (PII leakage, geolocation tracking)
- Supply-chain attacks via npm / Go modules / Flutter pubspec dependencies

Out of scope:
- Issues in third-party services we depend on (file with them directly)
- Theoretical attacks without a proof-of-concept
- Self-XSS / social engineering of end users

## Disclosure

We follow **coordinated disclosure**:
- Acknowledge receipt within 72 hours
- Provide a timeline within 7 days
- Public disclosure within 14 days of a fix being deployed (or 90 days from initial report, whichever is sooner)

Researchers who report responsibly will be credited in the [SECURITY-CREDITS.md](SECURITY-CREDITS.md) file.

## Estonian government coordination

If a security issue concerns the integrity of EE-ALARM re-broadcasting (e.g. a way to inject false alerts via this app), we will:
1. Notify [Päästeamet](mailto:info@rescue.ee), [RIA](mailto:info@ria.ee), and [SMIT](mailto:smit@smit.ee) within 24 hours
2. Coordinate disclosure timing with their operational requirements
3. Suspend the affected component if necessary while investigating

This commitment overrides our standard disclosure timeline above when public safety is at stake.
