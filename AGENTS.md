# AGENTS.md

This file provides guidance to Codex when working with code in this repository.

## Stack

- **Runtime**: Bun
- **Language**: TypeScript
- **Platform**: Node.js-compatible

## Commands

```bash
bun install          # Install dependencies
bun run dev          # Start development server / watch mode
bun run build        # Compile TypeScript
bun test             # Run all tests
bun test <file>      # Run a single test file
bun run lint         # Lint
bun run typecheck    # Type-check without emitting
```

## Code Style

- Keep files under 200 lines; split into focused modules when approaching this limit.
- Prefer modularity: one responsibility per file/module.

## Codex Sentinel

- Repo-local Codex skills live in `.agents/skills/`.
- The Codex Sentinel engine lives in `.agents/sentinel/`.
- Use the `sentinel`, `audit`, and `watch` skills when the user asks for repo health, context debt, or log-aware debugging.

## Context Map

- `.agents/skills/`       # Repo-local Codex skills (sentinel, watch, audit)
- `.agents/sentinel/`     # Codex Sentinel logic engine and state
- `.claude/skills/`       # Claude Code skills
- `.claude/sentinel/`     # Claude Sentinel logic engine and state
- `workflows/`            # n8n workflow JSON exports and logic
- `agents/`               # System prompts and AI persona definitions
- `combined.log`          # Primary application health log
