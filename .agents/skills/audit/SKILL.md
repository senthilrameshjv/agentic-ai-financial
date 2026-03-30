---
name: audit
description: Use when the user wants a quick, low-overhead context audit of the largest repository files without running the full sentinel workflow.
---

# Context Audit

Find the top 5 largest files in the repository and flag any that are missing from `AGENTS.md`.

## Instructions

1. Confirm `AGENTS.md` exists. If it does not, report that first.
2. Run a lightweight size audit.
   - On macOS/Linux, use:

```bash
#!/usr/bin/env bash
set -euo pipefail

PROJECT_DOC="AGENTS.md"
TOP_N=5
DEBT_COUNT=0

echo "=== Context Audit: Top $TOP_N Largest Files ==="
echo ""

while IFS= read -r file; do
  clean="${file#./}"
  if grep -qF "$clean" "$PROJECT_DOC" || grep -qF "$(basename "$clean")" "$PROJECT_DOC"; then
    echo "  OK            $clean"
  else
    echo "  CONTEXT DEBT  $clean"
    DEBT_COUNT=$((DEBT_COUNT + 1))
  fi
done < <(
  find . \
    -not -path './.git/*' \
    -not -path './node_modules/*' \
    -not -path './.agents/*' \
    -type f \
    -print0 \
    | while IFS= read -r -d '' file; do
        size=$(wc -c < "$file" | tr -d '[:space:]')
        printf '%s\t%s\n' "$size" "$file"
      done \
    | sort -rn \
    | head -n "$TOP_N" \
    | cut -f2-
)

echo ""
if [ "$DEBT_COUNT" -eq 0 ]; then
  echo "No context debt found."
else
  echo "$DEBT_COUNT file(s) flagged as Context Debt. Consider documenting them in AGENTS.md."
fi
```

   - On Windows, use the same logic with PowerShell equivalents if you cannot use Bash.
3. Summarize the output.
   - List files that are already documented.
   - List files that are context debt.
   - Suggest concise `AGENTS.md` entries for each flagged file.
