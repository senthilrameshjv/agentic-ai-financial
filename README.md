# Agentic AI Financial Workflows

This repository contains agentic AI workflow demos for financial services, built primarily on:

- `n8n` for orchestration
- `OpenAI` models for agent reasoning
- `Denodo` as the virtualized data layer
- `MCP` for tool access from workflow agents

The project is centered around practical workflow demos such as loan analysis, servicing, and compliance review, with supporting demo data, setup guides, and workflow exports.

## What’s In This Repo

The main assets in this repository are:

- `workflows/`
  - n8n workflow JSON exports
- `demo/`
  - demo scripts, test prompts, and SQL patches for demo data
- `agents/`
  - system prompts and persona definitions used by workflows
- `docs/`
  - workflow notes, refactor plans, and gap-analysis writeups
- `views.md`
  - reference for the Denodo financial views used by the workflows

## Key Workflows

### 1. Original working multi-tree flow

- [Loan Agent Flow - Multi-Tree with same MCP and openAI model.json](C:/Senthil/Projects/github-projects/agentic-ai-financial/workflows/Loan%20Agent%20Flow%20-%20Multi-Tree%20with%20same%20MCP%20and%20openAI%20model.json)

This is the baseline working export with three routed branches:

- `new_loan`
- `existing_loan`
- `compliance`

### 2. Compliance-enhanced fork

- [Loan Agent Flow - Multi-Tree with same MCP and openAI model - v2.json](C:/Senthil/Projects/github-projects/agentic-ai-financial/workflows/Loan%20Agent%20Flow%20-%20Multi-Tree%20with%20same%20MCP%20and%20openAI%20model%20-%20v2.json)

This keeps the same 3-branch shape and extends the compliance branch to explicitly use:

- `customer_complaints`
- `officer_transcripts`

### 3. Investigation-enhanced fork

- [Loan Agent Flow - Multi-Tree with same MCP and openAI model - v3.json](C:/Senthil/Projects/github-projects/agentic-ai-financial/workflows/Loan%20Agent%20Flow%20-%20Multi-Tree%20with%20same%20MCP%20and%20openAI%20model%20-%20v3.json)

This keeps the `v2` compliance behavior and adds a fourth branch:

- `investigation`

That branch works backward from complaint/transcript evidence to related customers, loans, and officers.

## Architecture

At a high level, the workflows operate like this:

```text
User / Chat Input
  -> n8n workflow router
  -> specialist AI agent nodes
  -> Denodo MCP tools
  -> Denodo virtual views
  -> underlying source systems
```

For the multi-node flow, the specialist branches are:

- underwriting-style analysis:
  - `Credit Analyst`
  - `Payment History Analyst`
  - `Property Analyst`
  - `Risk Synthesizer`
- servicing:
  - `Loan Servicing Agent`
- compliance:
  - `AML/KYC Agent`

## Data Layer

The workflows query Denodo-exposed financial views through MCP.

Important views include:

- `financial_customers`
- `financial_loans`
- `financial_underwriting`
- `financial_payments`
- `financial_properties`
- `financial_rates`
- `customer_complaints`
- `officer_transcripts`

Schema reference:

- [views.md](C:/Senthil/Projects/github-projects/agentic-ai-financial/views.md)

## Setup

### Quick start

For the original setup path:

- [SETUP.md](C:/Senthil/Projects/github-projects/agentic-ai-financial/SETUP.md)

For the current multi-node workflow:

- [SETUP-MULTI-NODE.md](C:/Senthil/Projects/github-projects/agentic-ai-financial/SETUP-MULTI-NODE.md)

The multi-node guide covers:

- starting `n8n`
- configuring the Denodo MCP server
- importing the workflow JSON
- wiring OpenAI credentials
- wiring MCP header auth
- applying demo SQL data fixes
- validating all six branch outcomes

## Demo Data and Testing

The repository includes demo SQL and testing artifacts so the workflow outcomes are data-driven rather than hard-coded in prompts.

Important files:

- setup SQL and branch patching:
  - [multi-tree-flow-data-fixes.sql](C:/Senthil/Projects/github-projects/agentic-ai-financial/demo/multi-tree-flow-data-fixes.sql)
- audit script:
  - [audit-multi-tree-coverage.js](C:/Senthil/Projects/github-projects/agentic-ai-financial/scripts/audit-multi-tree-coverage.js)
- gap analysis:
  - [multi-tree-flow-gap-analysis.md](C:/Senthil/Projects/github-projects/agentic-ai-financial/docs/multi-tree-flow-gap-analysis.md)
- test/setup planning:
  - [testing-and-gap-analysis.md](C:/Senthil/Projects/github-projects/agentic-ai-financial/docs/testing-and-gap-analysis.md)

## Demo Scripts

For the current live workflow demo, use:

- [demo-script-multi-node-v2.md](C:/Senthil/Projects/github-projects/agentic-ai-financial/demo/demo-script-multi-node-v2.md)

This is the canonical demo script for the current workflow variants and includes:

- exact prompts to type into the n8n chat UI
- expected branch routing
- expected terminal nodes
- presenter talking points
- the `v3` investigation scenario

## Typical Test Prompts

Examples for the current workflow variants:

```text
Analyze customer 18926 for loan eligibility
```

```text
Analyze customer 10117 for loan eligibility
```

```text
Check payment status for customer 20000
```

```text
Run AML review for customer 21001
```

```text
Find customers complaining about high mortgage rates
```

## Endpoints

Typical local endpoints used during setup and demo:

- n8n:
  - [http://localhost:5678](http://localhost:5678)
- Denodo MCP:
  - [http://localhost:8080/verticals/mcp](http://localhost:8080/verticals/mcp)

## Notes

- The project’s workflow behavior should come from the data and the workflow structure, not from hidden prompt hacks.
- Demo inserts for complaints and transcripts use `embed_ai(...)` so embedding columns are populated when supported by the underlying Denodo/Postgres path.
- Older migration notes and superseded demo scripts have been moved under `docs/archive/` and `demo/archive/` for manual review.

## Codex and Claude Repo Instructions

This repository also contains local AI-assistant guidance files:

- [AGENTS.md](C:/Senthil/Projects/github-projects/agentic-ai-financial/AGENTS.md)
- [CLAUDE.md](C:/Senthil/Projects/github-projects/agentic-ai-financial/CLAUDE.md)

Those files are for repository-aware coding assistants and are not the primary product documentation for the workflow demos.
