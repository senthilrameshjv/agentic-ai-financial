# Multi-Node Workflow Setup Guide

## Prerequisites

- Docker and Docker Compose
- OpenAI API key
- Denodo VDP server instance running
- Denodo MCP server configured for the `verticals` database

## What This Setup Enables

This guide sets up the multi-node loan workflow at:

- [http://localhost:5678/workflow/lM6azNe4F0EXjKHB](http://localhost:5678/workflow/lM6azNe4F0EXjKHB)

It supports three routed branches:

- `new_loan`
- `existing_loan`
- `compliance`

And these terminal outcomes:

- `Risk Synthesizer`
- `Flag for Human Review`
- `Loan Status OK`
- `Escalate to Collections`
- `Compliance Cleared`
- `File SAR Report`

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
- Create the admin user if this is a fresh install

### 7. Import the multi-node workflow

- Go to **Workflows**
- Choose **Import from File**
- Import:
  - [loan-agent-flow-v2-multi-tree.json](C:/Senthil/Projects/github-projects/agentic-ai-financial/workflows/loan-agent-flow-v2-multi-tree.json)

If you already have the workflow created live, you can instead open:

- [http://localhost:5678/workflow/lM6azNe4F0EXjKHB](http://localhost:5678/workflow/lM6azNe4F0EXjKHB)

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

### 10. Activate the workflow

- Save the workflow
- Activate it

### 11. Apply the multi-node demo data patch

Run:

- [multi-tree-flow-data-fixes.sql](C:/Senthil/Projects/github-projects/agentic-ai-financial/demo/multi-tree-flow-data-fixes.sql)

Notes:

- This patch keeps each branch scenario isolated.
- It uses `embed_ai('<text>')` for complaint and transcript inserts so the embedding columns are populated on insert.
- If your source schema does not yet allow `status = 'defaulted'`, add that allowed value first before running the servicing-negative part of the patch.

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

## Recommended Demo References

- setup flow:
  - [SETUP.md](C:/Senthil/Projects/github-projects/agentic-ai-financial/SETUP.md)
- multi-node demo script:
  - [demo-script-multi-node.md](C:/Senthil/Projects/github-projects/agentic-ai-financial/demo/demo-script-multi-node.md)
- multi-node runbook:
  - [demo-multi-node-flow.md](C:/Senthil/Projects/github-projects/agentic-ai-financial/demo/demo-multi-node-flow.md)
- gap analysis:
  - [multi-tree-flow-gap-analysis.md](C:/Senthil/Projects/github-projects/agentic-ai-financial/docs/multi-tree-flow-gap-analysis.md)

## Key Endpoints

- n8n:
  - [http://localhost:5678](http://localhost:5678)
- live workflow:
  - [http://localhost:5678/workflow/lM6azNe4F0EXjKHB](http://localhost:5678/workflow/lM6azNe4F0EXjKHB)
- Denodo MCP:
  - [http://localhost:8080/verticals/mcp](http://localhost:8080/verticals/mcp)
