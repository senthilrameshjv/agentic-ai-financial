---
name: sentinel
description: Use when the user wants a repository health scan, context debt audit, dead-link check, or guidance about what Codex should load into context first.
---

# Codex Sentinel

Audit repository context health and report context debt in a format optimized for Codex.

## Instructions

1. Run the Sentinel engine.
   - On macOS/Linux, run `bash .agents/sentinel/scanner.sh`.
   - On Windows, run `powershell -ExecutionPolicy Bypass -File .agents/sentinel/scanner.ps1`.
2. Parse the output.
   - `DEAD_LINK:` means `AGENTS.md` references a path that no longer exists.
   - `SIGNAL:DEBT|...` means a large file is missing from the `## Context Map`.
3. Score repository health.
   - Start at 100.
   - Deduct 10 points for each dead link.
   - Deduct 5 points for each undocumented file over 1000 estimated tokens.
   - Deduct 15 points if `AGENTS.md` is missing a `## Context Map`.
4. Report the result.
   - Show the grade (`A` to `F`).
   - List dead links.
   - List up to 3 heaviest undocumented files by estimated token weight.
5. Offer action.
   - Suggest exact `AGENTS.md` context-map entries for each flagged file.
