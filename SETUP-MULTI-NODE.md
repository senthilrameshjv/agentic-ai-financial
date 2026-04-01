# Multi-Node Workflow Setup Guide

## Prerequisites

- Docker and Docker Compose
- OpenAI API key
- Denodo VDP server instance running
- Denodo MCP server configured for the `verticals` database
- Denodo AI SDK MCP endpoint if you want to test the RAG variants

## What This Setup Enables

The base multi-node design supports three routed branches:

- `new_loan`
- `existing_loan`
- `compliance`

The current repo variants extend that baseline with:

- `investigation`
  - topic-led customer discovery from complaints and transcripts
- `rag_discovery`
  - Denodo AI SDK MCP work in progress

For semantic lookup in the investigation branch, the current Denodo query shape is:

- `vector_distance("embedding", 'input text')`

## Workflow Files

Use the workflow that matches the scenario you want to demo or test:

- stable structured baseline:
  - [multi-node-structured-flow.json](C:/Senthil/Projects/github-projects/agentic-ai-financial/workflows/multi-node-structured-flow.json)
- stable unstructured compliance variant:
  - [multi-node-unstructured-added.json](C:/Senthil/Projects/github-projects/agentic-ai-financial/workflows/multi-node-unstructured-added.json)
- stable investigation variant:
  - [multi-node-unstructured-v2-(query using transcript or complaints).json](C:/Senthil/Projects/github-projects/agentic-ai-financial/workflows/multi-node-unstructured-v2-%28query%20using%20transcript%20or%20complaints%29.json)
- RAG work in progress:
  - [multi-node-with-rag-added-(almost-working).json](C:/Senthil/Projects/github-projects/agentic-ai-financial/workflows/multi-node-with-rag-added-%28almost-working%29.json)
  - [multi-node-with-rag-session-lock-candidate.json](C:/Senthil/Projects/github-projects/agentic-ai-financial/workflows/multi-node-with-rag-session-lock-candidate.json)

Recommended default:

- use `multi-node-structured-flow.json` for the baseline deterministic flow
- use `multi-node-unstructured-added.json` when you want the compliance branch to use complaints and transcripts
- use `multi-node-unstructured-v2-(query using transcript or complaints).json` when you also want the investigation branch
- use `multi-node-with-rag-session-lock-candidate.json` only when actively testing the RAG follow-up and reset behavior

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

For the deterministic and investigation workflows, make sure these views are available:

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

### 6. Start the Denodo AI SDK MCP endpoint if testing RAG

If you are testing a RAG workflow variant, also make sure the Denodo AI SDK MCP endpoint is available.

Expected endpoint in the current RAG candidates:

- `http://host.docker.internal:8008/mcp`

### 7. Initialize n8n

- Open [http://localhost:5678](http://localhost:5678)
- Create the admin user if this is a fresh install

### 8. Import the workflow variant you want

- Go to **Workflows**
- Choose **Import from File**
- Import one of:
  - [multi-node-structured-flow.json](C:/Senthil/Projects/github-projects/agentic-ai-financial/workflows/multi-node-structured-flow.json)
  - [multi-node-unstructured-added.json](C:/Senthil/Projects/github-projects/agentic-ai-financial/workflows/multi-node-unstructured-added.json)
  - [multi-node-unstructured-v2-(query using transcript or complaints).json](C:/Senthil/Projects/github-projects/agentic-ai-financial/workflows/multi-node-unstructured-v2-%28query%20using%20transcript%20or%20complaints%29.json)
  - [multi-node-with-rag-session-lock-candidate.json](C:/Senthil/Projects/github-projects/agentic-ai-financial/workflows/multi-node-with-rag-session-lock-candidate.json)

Notes:

- `multi-node-unstructured-added.json` extends compliance with complaints and transcripts
- `multi-node-unstructured-v2-(query using transcript or complaints).json` adds investigation
- `multi-node-with-rag-session-lock-candidate.json` is a work-in-progress RAG test export and is not yet the canonical stable demo workflow

### 9. Configure OpenAI in n8n

- Open the workflow
- Open the shared `OpenAI Chat Model` node
- Attach or create your OpenAI credential

### 10. Configure Denodo MCP auth in n8n

- Open the deterministic MCP client nodes
- Use Header Auth
- Header name:
  - `Authorization`
- Header value:
  - `Basic YWRtaW46YWRtaW4=`

If you imported the RAG candidate, also verify:

- `MCP Client - AI SDK`

### 11. Activate the workflow

- Save the workflow
- Activate it

### 12. Apply the multi-node demo data patch if needed

Run:

- [multi-tree-flow-data-fixes.sql](C:/Senthil/Projects/github-projects/agentic-ai-financial/demo/multi-tree-flow-data-fixes.sql)

Notes:

- This patch keeps each branch scenario isolated.
- It uses `embed_ai('<text>')` for complaint and transcript inserts so the embedding columns are populated on insert.
- At query time, Denodo internally handles embedding of the search text inside `vector_distance("embedding", 'input text')`.
- If your source schema does not yet allow `status = 'defaulted'`, add that allowed value first before running the servicing-negative part of the patch.

## Stable Test Prompts

### New loan positive

```text
Analyze customer 18926 for loan eligibility
```

Expected branch:

- `new_loan`

### New loan negative

```text
Analyze customer 10117 for loan eligibility
```

Expected branch:

- `new_loan`

### Existing loan negative

```text
Check payment status for customer 20000
```

Expected branch:

- `existing_loan`

### Compliance negative

```text
Run AML review for customer 21001
```

Expected branch:

- `compliance`

### Investigation by topic

This prompt is for the investigation variant:

```text
Find customers complaining about high mortgage rates
```

Expected branch:

- `investigation`

## RAG Test Prompts

These prompts are for the RAG work-in-progress candidate only:

```text
What loan related tables are available
```

```text
5 highest approved loans with loan ID and customer ID
```

```text
Thanks. Reset RAG
```

## Recommended References

- setup flow:
  - [SETUP.md](C:/Senthil/Projects/github-projects/agentic-ai-financial/SETUP.md)
- current demo script:
  - [demo-script-multi-node-v2.md](C:/Senthil/Projects/github-projects/agentic-ai-financial/demo/demo-script-multi-node-v2.md)
- schema reference:
  - [views.md](C:/Senthil/Projects/github-projects/agentic-ai-financial/views.md)

## Key Endpoints

- n8n:
  - [http://localhost:5678](http://localhost:5678)

- Denodo MCP:
  - [http://localhost:8080/verticals/mcp](http://localhost:8080/verticals/mcp)

- Denodo AI SDK MCP:
  - `http://host.docker.internal:8008/mcp`
