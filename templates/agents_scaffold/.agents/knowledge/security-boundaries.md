# Security Boundaries & Isolation Guidelines

> Explicit security constraints and trust boundaries that AI agents must preserve across all implementation phases.

---

## 1. Network & Origin Boundaries

- **Interface Binding:** [e.g., Bind strictly to 127.0.0.1 for local services; zero public exposure without auth gateway]
- **CSRF & Origin Protection:** [State mutating endpoints must validate Origin/Referer headers and session tokens]
- **DNS Rebinding Defense:** [Validate Host header strictly against authorized hostnames]

---

## 2. Data Protection & Secrets Sanitization

- **Zero API Keys in Git:** Never commit secrets, tokens, private keys, or credentials to version control.
- **Log Redaction:** Sensitive user parameters, passwords, bearer tokens, and model transcripts must be redacted before outputting to stdout or persistent log sinks.
- **Input Sanitization:** All incoming requests must be validated against explicit schemas (Pydantic / Zod) before database operations.
