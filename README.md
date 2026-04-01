# Agentic AI Financial Workflows

This repository contains agentic AI workflow demos for financial services, built primarily on:

- `n8n` for orchestration
- `OpenAI` models for agent reasoning
- `Denodo` as the virtualized data layer
- `MCP` for tool access from workflow agents

The project focuses on practical workflow demos such as loan analysis, servicing, compliance review, investigation, and an in-progress Denodo AI SDK RAG path.

## What's In This Repo

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

### 1. Structured multi-node flow

- [multi-node-structured-flow.json](workflows/multi-node-structured-flow.json)

This is the baseline working export with three routed branches:

- `new_loan`
- `existing_loan`
- `compliance`

### 2. Unstructured-data fork

- [multi-node-unstructured-added.json](workflows/multi-node-unstructured-added.json)

This keeps the same 3-branch shape and extends the compliance branch to explicitly use:

- `customer_complaints`
- `officer_transcripts`

### 3. Investigation-enhanced fork

- [multi-node-unstructured-v2-(query using transcript or complaints).json](workflows/multi-node-unstructured-v2-%28query%20using%20transcript%20or%20complaints%29.json)

This keeps the unstructured compliance behavior and adds a fourth branch:

- `investigation`

That branch works backward from complaint/transcript evidence to related customers, loans, and officers.
For semantic lookup, Denodo handles query-text embedding internally via:

- `vector_distance("embedding", 'input text')`

### 4. RAG work in progress

- [multi-node-with-rag-added-(almost-working).json](workflows/multi-node-with-rag-added-%28almost-working%29.json)
- [multi-node-with-rag-session-lock-candidate.json](workflows/multi-node-with-rag-session-lock-candidate.json)

These are active work-in-progress variants for Denodo AI SDK RAG routing.
Use them for iterative validation, not as the canonical demo baseline yet.

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
- investigation:
  - complaint/transcript-led customer discovery
- RAG:
  - Denodo AI SDK MCP experiments

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

- [views.md](views.md)

## Setup

### Quick start

For the base setup path:

- [SETUP.md](SETUP.md)

For the current multi-node workflow setup:

- [SETUP-MULTI-NODE.md](SETUP-MULTI-NODE.md)

The multi-node guide covers:

- starting `n8n`
- configuring the Denodo MCP server
- importing the current workflow JSON files
- wiring OpenAI credentials
- wiring MCP header auth
- applying demo SQL data fixes
- validating the stable deterministic branches
- testing the RAG work-in-progress variants separately

## Demo Data and Testing

The repository includes demo SQL and testing artifacts so the workflow outcomes are data-driven rather than hard-coded in prompts.

Important files:

- setup SQL and branch patching:
  - [multi-tree-flow-data-fixes.sql](demo/multi-tree-flow-data-fixes.sql)
- audit script:
  - [audit-multi-tree-coverage.js](scripts/audit-multi-tree-coverage.js)
- gap analysis:
  - [multi-tree-flow-gap-analysis.md](docs/multi-tree-flow-gap-analysis.md)
- test/setup planning:
  - [testing-and-gap-analysis.md](docs/testing-and-gap-analysis.md)

## Demo Scripts

For the current live workflow demo, use:

- [demo-script-multi-node-v2.md](demo/demo-script-multi-node-v2.md)

This is the canonical demo script for the current workflow variants and includes:

- exact prompts to type into the n8n chat UI
- expected branch routing
- expected terminal nodes
- presenter talking points
- the current investigation scenario
- notes for the current RAG work-in-progress flow

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

```text
What loan related tables are available
```

## Endpoints

Typical local endpoints used during setup and demo:

- n8n:
  - [http://localhost:5678](http://localhost:5678)
- Denodo MCP:
  - [http://localhost:8080/verticals/mcp](http://localhost:8080/verticals/mcp)

## Notes

- The project's workflow behavior should come from the data and the workflow structure, not from hidden prompt hacks.
- Demo inserts for complaints and transcripts use `embed_ai(...)` so embedding columns are populated when supported by the underlying Denodo/Postgres path.
- At query time, the current Denodo vector-search syntax is `vector_distance("embedding", 'input text')`; the query text does not need an explicit `embed_ai(...)` wrapper.
- Denodo AI SDK RAG integration is currently a work in progress. The RAG workflow exports in `workflows/` are testing artifacts until session-pinning and reset behavior are fully confirmed.

## Codex and Claude Repo Instructions

This repository also contains local AI-assistant guidance files:

- [AGENTS.md](AGENTS.md)
- [CLAUDE.md](CLAUDE.md)

Those files are for repository-aware coding assistants and are not the primary product documentation for the workflow demos.
