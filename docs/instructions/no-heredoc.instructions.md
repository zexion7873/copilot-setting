---
description: 'Forbid terminal heredoc / redirection for writing file content; use file editing tools instead. Works around VS Code Copilot terminal corruption.'
applyTo: '**'
# Author reference only. This rule is also in copilot-instructions.md Hard Rules section.
---

# No Heredoc File Operations

Never use `cat`/`echo`/`printf`/`tee` with `>`/`>>`/`<< EOF` to write file content — VS Code terminal integration corrupts these (tab completion, escaping, exit 130).

- **Create / modify files** → use the file editing tool (Write / Edit)
- **Delete files** → `rm` is fine
- **Terminal still OK for** — package management, builds, tests, git, `ls`/`mkdir`/`rm`, downloads without piping to files
