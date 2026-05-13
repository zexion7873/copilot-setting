---
description: 'Forbid terminal heredoc / redirection for writing file content; use file editing tools instead. Works around VS Code Copilot terminal corruption.'
applyTo: '**'
---

# No Heredoc File Operations

Never use terminal heredoc, redirection, or `cat` / `echo` / `printf` / `tee` to write file content. VS Code's Copilot terminal integration corrupts these — tab characters trigger shell completion, escaping fails, exit code 130 truncates output.

## Forbidden

`cat`/`echo`/`printf`/`tee` with `>`/`>>`/`<< EOF` — all forbidden for writing file content.

## Required

- Create / modify files → use the file editing tool (Write / Edit)
- Delete files → `rm` is fine

## Terminal Still Allowed For

Package management, builds, tests, version control, running existing code, filesystem navigation (`ls`, `cd`, `mkdir`, `pwd`, `rm`), downloads without piping content to files.
