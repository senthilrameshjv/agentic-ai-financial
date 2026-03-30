# 🛡️ Claude Sentinel: AI Context Health Engine

**Claude Sentinel** is a "Senior AI Guardian" for [Claude Code](https://claude.ai) projects. It provides a suite of custom **Slash Commands** designed to minimize "Token Tax," eliminate hallucinations, and keep your AI collaborator perfectly synced with your codebase.

In the 2026 "Vibe-Coding" era, **Context is Currency.** Sentinel ensures you don't spend it on "Ghost Links" or undocumented bloat.

---

## 🚀 One-Command Injection

Inject the Sentinel engine and skills into any new project root without checking out this repo. Run this in your terminal:

```bash
curl -L https://github.com/senthilrameshjv/claude-context-audit/archive/main.tar.gz | tar -xz --strip-components=1 "claude-context-audit-main/.claude" && echo "✅ Sentinel Injected. Run /reload in Claude Code."
```



---

## 🧠 Core Capabilities

### 1. `/sentinel` — The Health Guardian
Audits your project's "Context Debt" and provides a letter grade (A-F).
* **Ghost Buster:** Flags dead links in `CLAUDE.md` to prevent hallucinations.
* **Token Weight:** Identifies "Heavy" files (>1,000 tokens) that eat your context window.
* **Map Validation:** Ensures your `## Context Map` is up-to-date and readable.

### 2. `/watch [logfile]` — The Frontline Bodyguard
Monitors your logs (e.g., `combined.log`) in real-time.
* **Auto-Lookup:** When an error occurs, it automatically finds the failing file.
* **Sentinel Sync:** Cross-references errors with the Sentinel Engine to warn you if the failing code is "undocumented or stale" before suggesting a fix.

### 3. `/audit` — The Initial Probe
A lightweight version of the scanner that finds the top 5 largest files and checks for their presence in your project documentation.

---

## 🛠️ Required Setup: The "GPS"

For the Sentinel to work at 100% efficiency, your `CLAUDE.md` must contain a `## Context Map` section. This acts as the "Map of the World" for the AI.

**Example `CLAUDE.md` entry:**
```markdown
## Context Map
- src/api/           # Core backend endpoints
- workflows/         # n8n/Automation JSON logic
- .claude/sentinel/  # Sentinel Engine (meta)
```

---

## 🧹 Maintenance Commands

Use these built-in Claude Code commands alongside Sentinel to stay lean:

| Command | When to use? | Token Impact |
| :--- | :--- | :--- |
| **`/compact`** | When a session gets long but you're on the same task. | Moderate Savings |
| **`/clear`** | When switching from one feature to a completely different one. | Massive Savings |
| **`/reload`** | After injecting new Sentinel skills. | Essential |

---

## 📁 Directory Structure

```text
.claude/
├── skills/
│   ├── sentinel/    # The /sentinel orchestrator (SKILL.md)
│   ├── watch/       # The /watch log monitor (SKILL.md)
│   └── audit/       # The /audit lightweight probe (SKILL.md)
└── sentinel/
    └── scanner.sh   # The core bash engine (The "Brain")
```

---

### 💡 Pro-Tip
Add the injection command as a shell alias in your `.zshrc` or `.bashrc` for instant deployment:
`alias sentinel-inject='curl -L https://github.com/senthilrameshjv/claude-context-audit/archive/main.tar.gz | tar -xz --strip-components=1 "claude-context-audit-main/.claude"'`

---

## Codex Support

This repository also includes a Codex-native setup for ChatGPT Codex.

- Use `AGENTS.md` at the repository root for Codex repository instructions.
- Use `.agents/skills/` for repo-local Codex skills.
- Use `.agents/sentinel/scanner.sh` on macOS/Linux.
- Use `.agents/sentinel/scanner.ps1` on Windows.

The Claude and Codex integrations are additive and coexist in the same repo:

- Claude uses `CLAUDE.md` and `.claude/...`
- Codex uses `AGENTS.md` and `.agents/...`
