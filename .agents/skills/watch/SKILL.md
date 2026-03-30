---
name: watch
description: Use when the user wants to inspect recent log errors and cross-check whether the failing code is documented in the repository context map.
---

# Sentinel Watcher

Inspect recent logs and add context-awareness before proposing a fix.

## Instructions

1. Tail the target log file.
   - Default to `combined.log`.
   - Read the last 50 lines first.
2. Detect notable failures.
   - Look for `ERROR`, `CRITICAL`, stack traces, or `500` status codes.
3. Cross-reference Sentinel state.
   - Extract the likely file path from the error.
   - On macOS/Linux, run `bash .agents/sentinel/scanner.sh | grep "FILE:[extracted_name]"`.
   - On Windows, run `powershell -ExecutionPolicy Bypass -File .agents/sentinel/scanner.ps1 | Select-String "FILE:[extracted_name]"`.
4. Report with context.
   - If the file has debt, start with: `Warning: error is in an undocumented file. Context may be stale.`
   - If the file is covered, start with: `Documentation is present for the failing area.`
5. Resolve.
   - Propose the likely code or config fix.
   - If the file is undocumented, also propose an `AGENTS.md` context-map entry.
