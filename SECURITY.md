# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in this project, please report it responsibly.

**Do NOT open a public issue.**

Instead, please email the maintainer directly or use [GitHub's private vulnerability reporting](https://github.com/zexion7873/copilot-setting/security/advisories/new).

## Scope

This repository contains GitHub Copilot configuration files (instructions, agents, prompts, skills). While these are not executable software, misconfigurations could potentially:

- Expose sensitive patterns or credentials through Copilot suggestions
- Introduce insecure coding practices via instruction files

## Best Practices

- Never include real API keys, passwords, or secrets in any configuration file
- Review Copilot-generated code before committing
- Keep your Copilot and VS Code extensions up to date
