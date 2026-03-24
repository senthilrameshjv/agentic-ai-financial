# Agentic AI Financial Demo

An AI-powered loan officer assistant built on **n8n + OpenAI + Denodo**. A loan officer types a natural language question; the AI agent autonomously queries 5–8 federated data sources via Denodo and returns a structured answer in seconds.

## Prerequisites

- [Rancher Desktop](https://rancherdesktop.io/) (or Docker Desktop) with Docker Compose
- Denodo Platform with the `verticals` database and views loaded (see `views.md`)
- Denodo MCP server installed and configured (see below)
- OpenAI API key

## Denodo MCP Server Setup

The Denodo MCP server must be running before starting the demo. It exposes Denodo views as tools that the AI agent can call.

### Configure the JDBC connection

In the Denodo MCP server configuration file, set the JDBC URL to point to your Denodo instance:

```properties
# Denodo JDBC connection
jdbc.url=jdbc:denodo://localhost:9999/verticals
jdbc.username=admin
jdbc.password=admin
```

> **JDBC URL format:** `jdbc:denodo://<host>:<port>/<database>`
> - Default Denodo VDP port: `9999`
> - Database name must match the one used in the MCP tool names (`verticals`)

### Start the MCP server

Follow the Denodo MCP server documentation to start it. Once running, verify it is accessible:

```bash
curl -u admin:admin http://localhost:8080/verticals/mcp
```

The server must be reachable at `http://localhost:8080/verticals/mcp` before proceeding.

## Prepare data for the demo scenario

The data is modified so that the 'happy path' works for one of the customers. 

UPDATE financial_customers SET risk_weighting = 9 WHERE customer_id = 10117;
UPDATE financial_loans SET interest_rate = 5.5 WHERE loan_id = 7581;
INSERT INTO verticals.financial_underwriting
    (underwriting_id, loan_id, credit_score, employment_history, financial_history)
  VALUES
    (2001, 7581, 575, 'Stable', 'Poor');

## Installation

### 1. Clone and configure environment

```bash
git clone <repo-url>
cd agentic-ai-financial
cp .env.example .env
```

Edit `.env` and fill in:

```
OPENAI_API_KEY=sk-...
N8N_ENCRYPTION_KEY=<any random 32-character string>
```

### 2. Start n8n

```bash
docker compose up -d
```

n8n will be available at `http://localhost:5678`.

## Configuration

### 3. Create OpenAI credential

1. Open `http://localhost:5678` → **Settings → Credentials → Add credential**
2. Search for **OpenAI API**
3. Paste your `OPENAI_API_KEY`
4. Save as **"OpenAi account"**

### 4. Create Denodo MCP credential

1. **Settings → Credentials → Add credential**
2. Search for **Header Auth**
3. Set:
   - **Name:** `Authorization`
   - **Value:** `Basic YWRtaW46YWRtaW4=`
4. Save as **"Header Auth account"**

> The value is Base64-encoded `username:password`. To generate your own:
> ```bash
> echo -n "your_user:your_password" | base64
> ```

### 5. Import and activate the workflow

1. **Workflows → Add workflow → Import from file**
2. Select `workflows/loan-officer-assistant.json`
3. Click **Activate** (toggle top-right)

### 6. Open the chat UI

Click the **chat bubble icon** on the workflow canvas, or navigate to the webhook chat URL shown in the Chat Trigger node.

## Running the Demo

See [`demo/demo-script.md`](demo/demo-script.md) for a full walkthrough with three escalating questions and suggested talking points.

**Quick start questions:**

```
Find customer Sarah Johnson and show me her profile and account balances.
```
```
Is Sarah at risk of defaulting on any of her loans?
```
```
Prepare a full pre-meeting briefing for my meeting with Sarah Johnson tomorrow.
```

## Architecture

```
Chat UI (n8n built-in)
    │
    ▼
AI Agent (GPT-4o, temp=0)
    │
    ├── Window Buffer Memory (20-turn context)
    │
    └── MCP Client → Denodo MCP Server (http://localhost:8080/verticals/mcp)
                          │
                          └── Denodo Virtual DataPort
                                    │
                                    ├── financial_customers
                                    ├── financial_acct
                                    ├── financial_loans
                                    ├── financial_payments
                                    ├── financial_underwriting
                                    ├── financial_properties
                                    ├── financial_rates
                                    ├── financial_loanofficers
                                    ├── customer_complaints
                                    └── officer_transcripts
```

## Project Structure

```
workflows/
  loan-officer-assistant.json   # Import this into n8n
agents/
  loan-officer-system-prompt.md # Agent instructions (embedded in workflow)
demo/
  demo-script.md                # Step-by-step demo guide
views.md                        # Denodo view schemas reference
docker-compose.yaml
.env.example
```
