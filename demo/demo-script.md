# Demo Script — Loan Officer Intelligence Assistant

## Setup Checklist

- [ ] Denodo MCP server running at `http://localhost:8080/verticals/mcp`
- [ ] n8n running (`docker compose up -d`, then open `http://localhost:5678`)
- [ ] Workflow imported and activated
- [ ] OpenAI credential configured in n8n (Settings → Credentials → OpenAI API)
- [ ] Denodo MCP credential configured in n8n:
      Settings → Credentials → Header Auth
        Name (header): `Authorization`
        Value: `Basic YWRtaW46YWRtaW4=`
      Assigned to the "MCP Client" node
- [ ] Data patches applied (see `scripts/data-gap-analysis.md`)
- [ ] Chat UI open (click the chat bubble icon on the active workflow)

---

## Demo Customer: Robert Logan (ID: 10117)

Robert Logan is a Platinum-tier, Mid-High income customer with a $593K mortgage. After the data patches, he carries every risk signal in the system — making him the ideal customer to demonstrate the full intelligence of the agent.

| Signal | Value |
|---|---|
| Risk weighting | 9 (High-Risk) |
| Credit score | 575 (below 620 threshold) |
| Active loan rate | 5.5% vs market 3.75% → 1.75% refinancing gap |
| Complaints on record | 10 |
| Officer meeting transcripts | 4 (2 modification, 2 phone) |

---

## The Story

> "As a loan officer, I need to prepare for customer meetings every day. Right now, I spend 30–60 minutes per customer pulling data from our loan origination system, CRM, payment processor, underwriting platform, and complaint system — manually. This assistant does it in seconds."

---

## Question 1 — Basic Data Federation

**What to say:** "Let's start simple. I want to look up a customer."

**Type in chat:**
```
Find Robert Logan and show me his profile and account balances.
```

**What happens:** Agent calls `denodo_verticals_query_financial_customers` to resolve the name, then fetches accounts.

**Talking point:** "No SQL, no system login. The agent resolved the name, found the customer ID, and pulled profile data from the bank's unified data layer through Denodo — instantly."

---

## Question 2 — Multi-Step Risk Reasoning

**What to say:** "Now let's ask something that requires reasoning, not just retrieval."

**Type in chat:**
```
Is Robert at risk of defaulting on any of his loans?
```

**What happens:** Agent fetches loans → payments → underwriting (credit score 575) → applies risk rules → flags High-Risk Customer (risk_weighting=9) and Credit Risk (score < 620).

**Expected flags:**
- 🔴 High-Risk Customer — risk_weighting = 9
- 🔴 Credit Risk — credit_score = 575 (below 620 threshold)

**Talking point:** "The agent made 3–4 tool calls, joined data across loan, payment, and underwriting records, applied business rules, and delivered a risk verdict. A human analyst would spend 20 minutes doing this across three systems."

---

## Question 3 — Full Pre-Meeting Briefing (Wow Moment)

**What to say:** "Now the real demo. I have a meeting with Robert tomorrow morning. I want a complete briefing — everything the system knows."

**Type in chat:**
```
Prepare a full pre-meeting briefing for my meeting with Robert Logan tomorrow.
```

**What happens (watch the n8n execution log):**
1. Resolves customer → profile (Platinum, Mid-High, risk_weighting=9)
2. Gets accounts
3. Gets loans → active loan: $593K @ 5.5%, 15yr
4. Gets payments → checks for delinquency
5. Gets underwriting → credit_score = 575
6. Gets property → computes LTV
7. Gets market rates → 3.75% for 15yr → flags 1.75% refinancing gap
8. Runs SQL on complaints → finds 10 complaints
9. Runs SQL on transcripts → finds 4 meetings (modification + phone)
10. Synthesizes everything into a structured briefing

**Expected output sections:**
- Customer Profile (Platinum, Mid-High, risk_weighting=9, age from DOB)
- Account Summary (table)
- Loan Portfolio ($593K @ 5.5%, 15yr, with LTV)
- Risk Signals (High-Risk Customer, Credit Risk)
- Refinancing Opportunity (5.5% vs 3.75% market — ~$X/month savings)
- Complaint History (summary of 10 complaints)
- Meeting History (2 modification meetings, 2 phone calls)
- Recommended Talking Points

**Talking point:** "9 tool calls. 5+ federated data sources. One structured briefing in under 30 seconds. Without Denodo, the agent can't reach this data. Without the agent, a loan officer needs a data analyst and 45 minutes. Together — it's instant, and anyone can use it."

---

## Bonus Question (if time allows)

**Type in chat:**
```
Which customers have both a high risk weighting AND the fewest loan payments? Show me the top 5.
```

**What happens:** Agent writes and executes a multi-table SQL join through `denodo_verticals_run_sql_query` joining `financial_customers`, `financial_loans`, and `financial_payments`.

**Talking point:** "This is portfolio-level intelligence — the kind of query that would take a data team a full day to produce. The agent wrote the SQL, ran it against Denodo's virtual schema, and returned an answer."

---

## Key Messages

1. **Denodo is the data foundation** — without it, the agent can't see across source systems. Denodo's semantic layer is what makes the agent intelligent about financial data.

2. **The agent is the reasoning layer** — without AI, Denodo's data still requires SQL expertise and manual synthesis. The agent turns data access into decision support.

3. **Together = time to insight goes from hours to seconds** — and it's conversational, so any loan officer can use it, not just data analysts.
