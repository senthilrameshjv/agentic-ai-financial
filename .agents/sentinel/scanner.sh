#!/usr/bin/env bash
# Codex Sentinel Engine v1.0
set -euo pipefail

PROJECT_DOC="${PROJECT_DOC:-AGENTS.md}"
CONTEXT_MAP_SECTION=$(awk '/## Context Map/{flag=1;next}/^##/{flag=0}flag' "$PROJECT_DOC" 2>/dev/null || true)

echo "--- SCAN START ---"

echo "SIGNAL:GHOST_CHECK"
{ grep -oE "(\./|[a-zA-Z0-9._-]+/)[a-zA-Z0-9._/-]+\.(ts|js|json|md|py|sh|ps1)" "$PROJECT_DOC" 2>/dev/null || true; } |
    sort -u |
    while read -r line; do
        if [ ! -e "$line" ] && [[ "$line" != *"/"* || -d "${line%/*}" ]]; then
            echo "DEAD_LINK:$line"
        fi
    done

find . -not -path '*/.*' -not -path './node_modules/*' -type f \( -name "*.ts" -o -name "*.js" -o -name "*.json" -o -name "*.md" \) |
    while read -r file; do
        FILE_SIZE=$(wc -c < "$file" | tr -d '[:space:]')
        TOKEN_EST=$((FILE_SIZE / 4))
        LINE_COUNT=$(wc -l < "$file" | tr -d '[:space:]')
        CLEAN_PATH="${file#./}"

        IN_MAP=0
        if echo "$CONTEXT_MAP_SECTION" | grep -qF "$CLEAN_PATH" || echo "$CONTEXT_MAP_SECTION" | grep -qF "$(basename "$CLEAN_PATH")"; then
            IN_MAP=1
        fi

        if [ "$IN_MAP" -eq 0 ] && ([ "$TOKEN_EST" -gt 500 ] || [ "$LINE_COUNT" -gt 150 ]); then
            echo "SIGNAL:DEBT|FILE:$CLEAN_PATH|TOKENS:$TOKEN_EST|LINES:$LINE_COUNT"
        fi
    done

echo "--- SCAN COMPLETE ---"
