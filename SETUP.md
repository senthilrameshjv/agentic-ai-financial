# Quick Setup Guide

## Prerequisites
- Docker & Docker Compose
- OpenAI API key
- Denodo VDP server instance running

## Steps

### 1. Start n8n
```bash
docker compose up -d
```

### 2. Configure Denodo MCP Server
Edit `denodo-mcp-server/config/application.properties` — update the last line:
```properties
vdp.datasource.jdbc-url=jdbc:vdb://YOUR_DENODO_HOST:49999/?noAuth=true
```

### 3. Run Denodo VDP Server
Start your Denodo Virtual Data Platform instance.

### 4. Tag Views for MCP
In Denodo, tag views you want exposed as tools with the tag `mcp`.

For the demo: Navigate to **verticals** database → **Financial Services - Banking - Data Products** folder and tag all views.

### 5. Start Denodo MCP Server
```bash
denodo-mcp-server/bin/denodo-mcp-server.bat
```
(Runs on `http://localhost:8080/verticals/mcp`)

### 6. Initialize n8n
- Open `http://localhost:5678`
- Create admin user and password ⚠️ **Cannot be recovered**

### 7. Import Workflow
- n8n UI → Workflows → Import
- Select `workflows/Loan Agent Flow (Flowise Migration).json`

### 8. Configure OpenAI
- In the workflow, open the **OpenAI** node
- Paste your OpenAI API key

### 9. Test
- Activate the workflow
- Open chat (bubble icon)
- Type: `Analyze customer 10117 for loan eligibility`

## Key Endpoints
- **n8n**: http://localhost:5678
- **Denodo MCP**: http://localhost:8080/verticals/mcp
