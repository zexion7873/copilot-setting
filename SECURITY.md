# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in this project, please report it responsibly.

**Do NOT open a public issue.**

Instead, please use [GitHub's private vulnerability reporting](https://github.com/zexion7873/copilot-setting/security/advisories/new).

## Scope

This repository ships GitHub Copilot configuration content (instructions, agents, skills, prompts, hooks) plus shell scripts that execute on user machines: the pre-tool-use hook (`.github/hooks/scripts/block-dangerous-commands.sh`, runs on agent tool-use events in downstream repos), the style-guide validator (`.github/scripts/validate-style-guide.sh`), and the opt-in pre-commit hook (`.githooks/pre-commit`).

In scope:

- Vulnerabilities in or tampering with any shipped shell script (e.g. fail-open parsing bugs in the hook)
- Configuration content that could expose sensitive patterns or credentials through Copilot suggestions
- Instruction files that introduce insecure coding practices

Out of scope: bypassing the dangerous-command block-list via encoding, aliases, or variable indirection — the hook is a last-resort safety net, not a sandbox (see `AGENTS.md`); downstream repos should run agents in restricted-permission environments.

## Best Practices

- Never include real API keys, passwords, or secrets in any configuration file
- Review Copilot-generated code before committing
- Keep your Copilot and VS Code extensions up to date
