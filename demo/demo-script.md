# Demo Script — Loan Officer Intelligence Assistant

## Setup Checklist

- [ ] Denodo MCP server running at `http://localhost:8080/verticals/mcp`
- [ ] n8n running (`docker compose up -d`, then open `http://localhost:5678`)
- [ ] Workflow imported and activated
- [ ] OpenAI credential configured in n8n (Settings → Credentials → OpenAI API)
- [ ] Denodo MCP credential configured in n8n:
      Settings → Credentials → HTTP Header Auth
        Name (header): `Authorization`
        Value: `Basic YWRtaW46YWRtaW4=`
      Assigned to the "Denodo MCP Tools" node
- [ ] Chat UI open (click the chat bubble icon on the active workflow)

---

## The Story

> "As a loan officer, I need to prepare for 10 customer meetings a day. Right now, I spend 30–60 minutes per customer pulling data from our loan origination system, CRM, payment processor, underwriting platform, and complaint system — manually. This assistant does it in 10 seconds."

---

## Question 1 — Basic Data Federation

**What to say:** "This first question is simple — but notice it hits our unified data layer in one shot."

**Type in chat:**
```
Find customer Sarah Johnson and show me her profile and account balances.
```

**What happens:** Agent calls `denodo_verticals_query_financial_customers` to resolve the name, then `denodo_verticals_query_financial_acct` for balances.

**Talking point:** "No SQL, no system login, no data download. The agent resolved the name, found the customer ID, and pulled data from two separate source systems through Denodo — in one turn."

---

## Question 2 — Multi-Step Reasoning Across 3 Views

**What to say:** "Now let's ask something that requires the agent to reason, not just retrieve."

**Type in chat:**
```
Is Sarah at risk of defaulting on any of her loans?
```

**What happens:** Agent calls loans → then payments per loan → then underwriting/credit score → applies risk rules → returns an assessment.

**Talking point:** "The agent made 3–4 tool calls, joined loan + payment + credit data, applied business rules about missed payments and credit scores, and gave a risk verdict. A human analyst would spend 20 minutes doing this manually across three systems."

---

## Question 3 — The Full Briefing (Wow Moment)

**What to say:** "Now the real demo. I have a meeting with Sarah tomorrow. I want a complete briefing."

**Type in chat:**
```
Prepare a full pre-meeting briefing for my meeting with Sarah Johnson tomorrow.
```

**What happens (watch the n8n execution log):**
1. Resolves customer → gets profile
2. Gets accounts
3. Gets all loans
4. For each active loan: gets payments, underwriting, property value
5. Gets current market rates → compares to Sarah's loan rate
6. Runs SQL against complaints table → finds any issues
7. Runs SQL against transcripts table → pulls meeting history
8. Synthesizes everything into a structured briefing with risk flags and talking points

**Expected output sections:**
- Customer Profile (income band, risk tier, loyalty)
- Account Summary (table)
- Loan Portfolio (table with LTV)
- Risk Signals (flagged issues)
- Refinancing Opportunity (if rate gap > 1%)
- Complaint History
- Meeting History
- Recommended Talking Points

**Talking point:** "8 tool calls. 5 virtual data sources. 1 comprehensive briefing. Without Denodo, the agent can't reach this federated data. Without the agent, a loan officer needs a data analyst and 45 minutes. Together — 15 seconds."

---

## Bonus Question (if time allows)

**Type in chat:**
```
Which customers have both a high risk weighting AND missed payments in the last 6 months? Show me the top 5.
```

**What happens:** Agent writes and runs a multi-table SQL join query through `denodo_verticals_run_sql_query` across `financial_customers`, `financial_loans`, and `financial_payments`.

**Talking point:** "This is portfolio-level intelligence — the kind of analysis that would take a data team a full day. The agent wrote the SQL, validated it against Denodo's virtual schema, and ran it. This is what 'proactive risk management' looks like with agentic AI."

---

## Key Messages to Leave Audience With

1. **Denodo is the data foundation** — without it, the agent can't see across source systems. Denodo's semantic layer is what makes the agent intelligent about financial data.

2. **The agent is the reasoning layer** — without AI, Denodo's data still requires a SQL expert and manual synthesis. The agent turns data access into decision support.

3. **Together = time to insight goes from hours to seconds** — and it's conversational, so any loan officer can use it, not just data analysts.
