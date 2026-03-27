# n8n Loan Agent Flow

Converted from Flowise "Loan Agent Flow New Agents.json" to n8n format.

## Architecture

4 sequential AI agents that collaborate autonomously to produce a loan decision:

```
Webhook Trigger → Extract Input → Credit Analyst → Payment Analyst → Property Analyst → Risk Synthesizer → Response
```

## Agent Tools (Denodo MCP)

Each agent has scoped access to Denodo MCP tools at `http://host.docker.internal:8080/verticals/mcp`:

| Agent | MCP Tools |
|-------|-----------|
| Credit Analyst | `query_financial_customers`, `query_financial_loans`, `query_financial_underwriting` |
| Payment History Analyst | `query_financial_loans`, `query_financial_payments` |
| Property Analyst | `query_financial_loans`, `query_financial_properties` |
| Risk Synthesizer | `query_financial_rates` |

## Import to n8n

1. Open n8n at http://localhost:5678
2. Go to **Workflows** → **Add Workflow**
3. Click the three dots menu → **Import from File**
4. Select `loan-agent-flow-n8n.json`

## Required Credentials

### 1. OpenAI API Credential
- Name: `OpenAI API` (or update the credential ID in the JSON)
- Type: OpenAI API
- Required for: All 4 agent nodes

### 2. Denodo MCP Auth (HTTP Header Auth)
- Name: `Denodo MCP Auth`
- Type: HTTP Header Auth
- Header Name: `Authorization`
- Header Value: `Basic YWRtaW46YWRtaW4=`

## Testing the Workflow

```bash
# Trigger the loan decision agent
curl -X POST http://localhost:5678/webhook/loan-decision \
  -H "Content-Type: application/json" \
  -d '{"chatInput": "Analyze customer 20000 for loan eligibility"}'
```

## Differences from Flowise

| Flowise | n8n |
|---------|-----|
| Agentflow type | Webhook + Agent nodes |
| Built-in MCP tool | MCP tool via LangChain agent |
| Sequential edges | Main connections |
| Chat input | Webhook body |

## Troubleshooting

### MCP Connection Issues
- Ensure Denodo MCP server is running: `http://host.docker.internal:8080/verticals/mcp`
- From Docker, `host.docker.internal` resolves to the host machine
- Verify Basic Auth credentials are correct

### Agent Not Executing
- Check OpenAI credential is configured
- Verify model `gpt-4o` is available in your OpenAI account
- Check n8n execution logs for errors
