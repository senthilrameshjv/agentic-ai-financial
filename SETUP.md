# Multi-Node Workflow Setup Guide

## Prerequisites

- Docker and Docker Compose
- OpenAI API key
- Denodo VDP server instance running
- Denodo MCP server configured for the `verticals` database
- Denodo AI SDK MCP endpoint if you want to test the RAG variants

## What This Setup Enables

The following branching are supported

- `new_loan`
- `existing_loan`
- `compliance`
- `investigation`
  - topic-led customer discovery from complaints and transcripts
- `rag_discovery`
  - Denodo AI SDK MCP work in progress

For semantic lookup in the investigation branch, the current Denodo query shape is:

- `vector_distance("embedding", 'input text')`

## Workflow Files

Refer workflows/final-workflow-with-unstructured.json for the final flow. You can refer to workflows/staging-workflows for iterative workflows if you need any previous version. 

## Steps

### 1. Start n8n

```bash
docker compose up -d
```

### 2. Configure the Denodo MCP server

Edit `denodo-mcp-server/config/application.properties` and update the JDBC URL:

```properties
vdp.datasource.jdbc-url=jdbc:vdb://YOUR_DENODO_HOST:DENODO_PORT/?noAuth=true  (make sure this host and port can be reached from your Denodo MCP server location)
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

(The last two are two new views that are not in standard demo. They point to unstructured data stored in Postgres/Pgvector. Their VQLs can be found in vql/ folder. You can import the data for them from sql/ folder using 

psql -U <username> -d <database> -f customer_complaints.sql
psql -U <username> -d <database> -f officer_transcripts.sql

)

### 5. Start the Denodo MCP server

```bash
denodo-mcp-server/bin/denodo-mcp-server.bat
```

Expected endpoint:

- `http://host.docker.internal:8080/verticals/mcp` 

<!-- If your Denodo is running on container and the container is running on a specific network like denodo-net (SE demo uses this network), run

 `docker network connect denodo-net n8n`

Now you would be able to point the mcp endpoint to 

 `http://denodo-platform-demo:8080 -->

### 6. Start the Denodo AI SDK MCP endpoint if testing RAG

If you are testing a RAG workflow variant, also make sure the Denodo AI SDK MCP endpoint is available.

Expected endpoint in the current RAG candidates:

- `http://host.docker.internal:8008/mcp`

### 7. Initialize n8n

- Open [http://localhost:5678](http://localhost:5678)
- Create the admin user if this is a fresh install (Dont forget the password, it can't be recovered)

### 8. Import the workflow variant you want

- Go to **Workflows**
- Choose **Import from File**
- Import workflows/final-workflow-with-unstructured.json


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

  Change the above base64 encoded value if you are going to use different user than admin:admin using https://mixedanalytics.com/tools/basic-authentication-generator/


### 11. Activate the workflow

- Save the workflow


### 12. Apply the multi-node demo data patch if needed

Run:

- [multi-tree-flow-data-fixes.sql](demo/multi-tree-flow-data-fixes.sql) (if there are any errors in delete statements, they can be ignored. Its possibly deleting some of the fixes i did during testing)

Notes:

- This patch keeps each branch scenario isolated.
- It uses `embed_ai('<text>')` for complaint and transcript inserts so the embedding columns are populated on insert.
- At query time, Denodo internally handles embedding of the search text inside `vector_distance("embedding", 'input text')`.

## Stable Test Prompts (also available at demo/test-prompts.md)

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


- current demo script:
  - [demo-script-multi-node-v2.md](demo/demo-script-multi-node-v2.md)
- schema reference:
  - [views.md](views.md)

## Key Endpoints

- n8n:
  - [http://localhost:5678](http://localhost:5678)

- Denodo MCP:
  - [http://localhost:8080/verticals/mcp](http://localhost:8080/verticals/mcp)

- Denodo AI SDK MCP:
  - `http://localhost:8008/mcp`
