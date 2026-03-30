# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

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

- Keep files under 200 lines — split into focused modules when approaching this limit.
- Prefer modularity: one responsibility per file/module.

## Context Map
- .claude/skills/       # Custom AI commands (sentinel, watch, audit)
- .claude/sentinel/     # The Sentinel logic engine and state
- workflows/            # n8n workflow JSON exports and logic
- agents/               # System prompts and AI persona definitions
- combined.log          # Primary application health log

