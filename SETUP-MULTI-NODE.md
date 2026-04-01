# Multi-Node Workflow Setup Guide

## Prerequisites

- Docker and Docker Compose
- OpenAI API key
- Denodo VDP server instance running
- Denodo MCP server configured for the `verticals` database

## What This Setup Enables

The base multi-node design supports three routed branches:

- `new_loan`
- `existing_loan`
- `compliance`

Across the newer workflow variants in this repo, those branches support these terminal outcomes:

- `Risk Synthesizer`
- `Flag for Human Review`
- `Loan Status OK`
- `Escalate to Collections`
- `Compliance Cleared`
- `File SAR Report`

The newest workflow fork also adds:

- `investigation`

That branch accepts topic-led prompts without a customer id and works backward from complaint/transcript evidence to related customers, loans, and officers.

## Workflow Files

Use the workflow that matches the scenario you want to demo:

- original working multi-tree flow:
  - [Loan Agent Flow - Multi-Tree with same MCP and openAI model.json](workflows/Loan%20Agent%20Flow%20-%20Multi-Tree%20with%20same%20MCP%20and%20openAI%20model.json)
- compliance-enhanced fork:
  - [Loan Agent Flow - Multi-Tree with same MCP and openAI model - v2.json](workflows/Loan%20Agent%20Flow%20-%20Multi-Tree%20with%20same%20MCP%20and%20openAI%20model%20-%20v2.json)
- investigation-enhanced fork:
  - [Loan Agent Flow - Multi-Tree with same MCP and openAI model - v3.json](workflows/Loan%20Agent%20Flow%20-%20Multi-Tree%20with%20same%20MCP%20and%20openAI%20model%20-%20v3.json)

Recommended default:

- use `v2` when you want the compliance branch to explicitly use `customer_complaints` and `officer_transcripts`
- use `v3` when you also want the new topic-led `investigation` branch

## Steps

### 1. Start n8n

```bash
docker compose up -d
```

### 2. Configure the Denodo MCP server

Edit `denodo-mcp-server/config/application.properties` and update the JDBC URL:

```properties
vdp.datasource.jdbc-url=jdbc:vdb://YOUR_DENODO_HOST:49999/?noAuth=true
```

### 3. Run Denodo VDP

Start your Denodo Virtual Data Platform instance.

### 4. Tag the required views for MCP

In Denodo, tag the views you want exposed through MCP with the tag `mcp`.

For this workflow, make sure these views are available:

- `financial_customers`
- `financial_loans`
- `financial_underwriting`
- `financial_payments`
- `financial_properties`
- `financial_rates`
- `customer_complaints`
- `officer_transcripts`

### 5. Start the Denodo MCP server

```bash
denodo-mcp-server/bin/denodo-mcp-server.bat
```

Expected endpoint:

- `http://localhost:8080/verticals/mcp`

### 6. Initialize n8n

- Open [http://localhost:5678](http://localhost:5678)
- Create the admin user if this is a fresh install (dont forget password, can't be recovered)

### 7. Import the workflow variant you want

- Go to **Workflows**
- Choose **Import from File**
- Import one of:
  - [Loan Agent Flow - Multi-Tree with same MCP and openAI model.json](C:/Senthil/Projects/github-projects/agentic-ai-financial/workflows/Loan%20Agent%20Flow%20-%20Multi-Tree%20with%20same%20MCP%20and%20openAI%20model.json)
  - [Loan Agent Flow - Multi-Tree with same MCP and openAI model - v2.json](C:/Senthil/Projects/github-projects/agentic-ai-financial/workflows/Loan%20Agent%20Flow%20-%20Multi-Tree%20with%20same%20MCP%20and%20openAI%20model%20-%20v2.json)
  - [Loan Agent Flow - Multi-Tree with same MCP and openAI model - v3.json](C:/Senthil/Projects/github-projects/agentic-ai-financial/workflows/Loan%20Agent%20Flow%20-%20Multi-Tree%20with%20same%20MCP%20and%20openAI%20model%20-%20v3.json)

Notes:

- `v2` keeps the original 3-branch shape and extends the compliance branch to use complaints and transcripts explicitly.
- `v3` keeps the `v2` compliance behavior and adds a fourth `investigation` branch for topic-led search.

### 8. Configure OpenAI in n8n

- Open the workflow
- Open the shared `OpenAI Chat Model` node
- Attach or create your OpenAI credential

### 9. Configure Denodo MCP auth in n8n

- Open the shared `MCP Client` node
- Use Header Auth
- Header name:
  - `Authorization`
- Header value:
  - `Basic YWRtaW46YWRtaW4=`

If you import `v3`, also verify:

- `MCP Client - Investigation`

It should point to the same endpoint and use the same Header Auth credential.

### 10. Activate the workflow

- Save the workflow
- Activate it

### 11. Apply the multi-node demo data patch if needed

Run:

- [multi-tree-flow-data-fixes.sql](demo/multi-tree-flow-data-fixes.sql)

Notes:

- This patch keeps each branch scenario isolated.
- It uses `embed_ai('<text>')` for complaint and transcript inserts so the embedding columns are populated on insert.
- If your source schema does not yet allow `status = 'defaulted'`, add that allowed value first before running the servicing-negative part of the patch.

Current live data may already include these scenarios, but the patch remains the setup source of truth for restoring them deterministically.

### 12. Verify the patched data

The SQL file includes verification queries for:

- Robert Logan (`10117`) as the underwriting-negative customer
- Jane Doe (`20000`) as the servicing-negative customer
- Daniel Mercer (`21001`) as the compliance-negative customer

## Test Prompts

After activation, open the chat bubble in n8n and run these prompts.

### New loan positive

```text
Analyze customer 18926 for loan eligibility
```

Expected branch:

- `new_loan`

Expected terminal node:

- `Risk Synthesizer`

### New loan negative

```text
Analyze customer 10117 for loan eligibility
```

Expected branch:

- `new_loan`

Expected terminal node:

- `Flag for Human Review`

### Existing loan positive

```text
Check payment status for customer 18926
```

Expected branch:

- `existing_loan`

Expected terminal node:

- `Loan Status OK`

### Existing loan negative

```text
Check payment status for customer 20000
```

Expected branch:

- `existing_loan`

Expected terminal node:

- `Escalate to Collections`

### Compliance positive

```text
Run AML review for customer 10033
```

Expected branch:

- `compliance`

Expected terminal node:

- `Compliance Cleared`

### Compliance negative

```text
Run AML review for customer 21001
```

Expected branch:

- `compliance`

Expected terminal node:

- `File SAR Report`

### Investigation by topic

This prompt is only for the `v3` workflow:

```text
Find customers complaining about high mortgage rates
```

Expected branch:

- `investigation`

Expected terminal node:

- `Return Investigation Results`

Best expected customer:

- Jane Doe (`20000`)

Optional second `v3` investigation prompt:

```text
Show suspicious source of funds cases
```

Best expected customer:

- Daniel Mercer (`21001`)

## Branch Summary by Workflow Version

### Original working flow

- branches:
  - `new_loan`
  - `existing_loan`
  - `compliance`
- best for:
  - baseline multi-branch demo

### v2

- branches:
  - `new_loan`
  - `existing_loan`
  - `compliance`
- adds:
  - explicit complaint/transcript usage inside the compliance branch
- best for:
  - AML/KYC demos that need evidence from unstructured views

### v3

- branches:
  - `new_loan`
  - `existing_loan`
  - `compliance`
  - `investigation`
- adds:
  - topic-led entity discovery using complaint/transcript embeddings
- best for:
  - signal-first demos where the operator does not start with a customer id

## Recommended Demo References

- setup flow:
  - [SETUP.md](C:/Senthil/Projects/github-projects/agentic-ai-financial/SETUP.md)
- canonical current demo script:
  - [demo-script-multi-node-v2.md](C:/Senthil/Projects/github-projects/agentic-ai-financial/demo/demo-script-multi-node-v2.md)
- gap analysis:
  - [multi-tree-flow-gap-analysis.md](C:/Senthil/Projects/github-projects/agentic-ai-financial/docs/multi-tree-flow-gap-analysis.md)

## Key Endpoints

- n8n:
  - [http://localhost:5678](http://localhost:5678)

- Denodo MCP:
  - [http://localhost:8080/verticals/mcp](http://localhost:8080/verticals/mcp)
