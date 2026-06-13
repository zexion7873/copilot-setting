---
description: 'Load when an agent would write file content via the terminal — cat/echo/printf/tee with >, >>, or << EOF heredocs. Triggers on: any terminal step that creates, overwrites, or appends a file. Use Write/Edit instead; the ban is only on WRITING content, not rm/builds/git/tests.'
applyTo: '**'
---

# No Heredoc File Operations

Never use `cat`/`echo`/`printf`/`tee` with `>`/`>>`/`<< EOF` to write file content — VS Code terminal integration corrupts these (tab completion, escaping, exit 130).

- **Create / modify files** → use the file editing tool (Write / Edit)
- **Delete files** → `rm` is fine
- **Terminal still OK for** — package management, builds, tests, git, `ls`/`mkdir`/`rm`, downloads without piping to files
