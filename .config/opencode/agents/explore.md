---
description: Explorer agent that inspect the codebase and find the relevant files to implement the request.
mode: subagent
model: opencode-go/deepseek-v4-flash
temperature: 0.1
tools:
  write: true
  edit: true
  bash: true
  webfetch: true
permission:
  edit: allow
  bash: allow
  webfetch: allow
---
