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

> "As a loan officer, I need to prepare for customer meetings every day. Right now, I spend 30–60 minutes per customer pulling data from our loan origination system, CRM, payment processor, underwriting platform, and complaint system — manually, across multiple logins. This assistant does it in seconds — by connecting to all of them through Denodo."

---

## Act 1: The MCP Moat

> **The claim:** One AI agent. One MCP endpoint. Eight source systems — Oracle, SQL Server, PostgreSQL, Snowflake, REST APIs, and Salesforce. None of those systems speak MCP natively. Denodo is the bridge.

---

### Question 0 — The Data Map (open with this)

**What to say:** "Before we look up a customer, let me show you what's actually under the hood."

**Type in chat:**
```
Before we get into Robert's details — can you tell me which systems you'll need to access to prepare his briefing, and where each piece of data comes from?
```

**What happens:** Agent lists all tools with their `[Source: ...]` labels — Oracle CRM, Core Banking (SQL Server), Loan Origination System (Oracle), Payment Ledger (PostgreSQL), Underwriting Platform (SQL Server), Property Appraisal API, Market Rates API, Salesforce CRM, Snowflake document store.

**Talking point:** "Oracle doesn't have MCP. SQL Server doesn't. PostgreSQL doesn't. Snowflake doesn't. External REST APIs don't. Denodo is the single MCP bridge to all of them. And this extends to any system Denodo connects to — Bloomberg, FiServ, mainframes, any database or API your bank runs."

---

### Question 1 — Basic Data Federation

**What to say:** "Now let's look up the customer."

**Type in chat:**
```
Find Robert Logan and show me his profile and account balances.
```

**What happens:** Agent calls `denodo_verticals_query_financial_customers` (Oracle CRM) to resolve the name, then fetches accounts from Core Banking (SQL Server).

**Talking point:** "No SQL, no system login. The agent resolved the name, found the customer ID in Oracle CRM, and pulled account balances from the Core Banking SQL Server — through Denodo's single unified layer."

---

### Question 2 — Multi-Step Risk Reasoning

**What to say:** "Now let's ask something that requires reasoning across multiple systems."

**Type in chat:**
```
Is Robert at risk of defaulting on any of his loans?
```

**What happens:** Agent fetches loans (Oracle LOS) → payments (PostgreSQL) → underwriting (SQL Server) → applies risk rules → flags High-Risk Customer and Credit Risk.

**Expected flags:**
- 🔴 High-Risk Customer — risk_weighting = 9
- 🔴 Credit Risk — credit_score = 575 (below 620 threshold)

**Talking point:** "3–4 tool calls crossing Oracle, PostgreSQL, and SQL Server — all federated through Denodo. Watch the response footer: 'Data federated live from: Oracle CRM, Loan Origination System (Oracle), Payment Ledger (PostgreSQL), Underwriting & Credit Platform (SQL Server).' That's the moat."

---

## Act 2: Real-Time vs. The Warehouse

> **The claim:** No ETL. No pipeline. No stale data. Denodo virtualizes data where it lives — every answer is current at query time.

---

### Question 2b — The Rate Freshness Challenge

**What to say:** "Here's a question that cuts right to the Snowflake vs. Denodo debate."

**Type in chat:**
```
How confident are you that Robert's current market rate comparison is accurate right now — not from last night's batch or last week's data warehouse load?
```

**What happens:** Agent calls `financial_rates` (Market Rates API) and returns the current rate with the live-feed note: *"Rate data sourced live from the Market Rates REST API via Denodo — reflects current market conditions, not a cached or batch-loaded snapshot."*

**Talking point:** "In Snowflake or Databricks, this rate landed in the warehouse on a schedule — potentially 12–24 hours ago. Denodo calls the Market Rates REST API live at query time. For a loan officer making a refinancing recommendation in a live meeting, those hours matter. The customer might lock in a rate that's already moved."

---

### Question 3 — Full Pre-Meeting Briefing (Wow Moment)

**What to say:** "Now the real demo. I have a meeting with Robert tomorrow. I want everything."

**Type in chat:**
```
Prepare a full pre-meeting briefing for my meeting with Robert Logan tomorrow.
```

**What happens (watch the n8n execution log):**
1. Resolves customer → Oracle CRM (profile, risk_weighting=9)
2. Gets accounts → Core Banking SQL Server
3. Gets loans → Loan Origination System Oracle ($593K @ 5.5%, 15yr)
4. Gets payments → Payment Ledger PostgreSQL (checks delinquency)
5. Gets underwriting → Underwriting SQL Server (credit_score = 575)
6. Gets property → Property Appraisal REST API (computes LTV)
7. Gets market rates → Market Rates REST API (3.75% → 1.75% gap)
8. Runs SQL on complaints → Salesforce API (10 complaints)
9. Runs SQL on transcripts → Snowflake (4 meetings)
10. Synthesizes into structured briefing with "Data Sources Accessed" table

**Expected output sections:**
- Customer Profile (Platinum, Mid-High, risk_weighting=9)
- Account Summary (table)
- Loan Portfolio ($593K @ 5.5%, 15yr, with LTV)
- Risk Signals (High-Risk Customer, Credit Risk)
- Refinancing Opportunity (5.5% vs 3.75% market — monthly savings)
- Complaint History (summary of 10 complaints)
- Meeting History (2 modification meetings, 2 phone calls)
- **Data Sources Accessed** (table showing all 8 systems queried)
- Recommended Talking Points

**Talking point:** "9 tool calls crossing Oracle, SQL Server, PostgreSQL, Snowflake, REST APIs, and Salesforce. One structured briefing in under 30 seconds — with no data copied anywhere. Without Denodo, the agent can't reach most of these systems. Without the agent, a loan officer needs a data analyst and 45 minutes."

---

### Question 4 — Portfolio Cross-Source Join

**What to say:** "One more — portfolio-level intelligence. This one would take a data team a day without Denodo."

**Type in chat:**
```
Give me a portfolio view: show me the top 5 customers with the highest risk weighting who also have approved loans where the current market rate for their term is more than 1% below their loan rate. Show their name, loan amount, current rate, market rate, and the gap.
```

**What happens:** Agent writes and executes a 3-table SQL join via `denodo_verticals_run_sql_query`:
```sql
SELECT
  c.first_name || ' ' || c.last_name AS customer_name,
  c.risk_weighting,
  l.loan_id,
  l.loan_amount,
  l.interest_rate AS loan_rate,
  r.interest_rate AS market_rate,
  l.interest_rate - r.interest_rate AS rate_gap
FROM financial_customers c
JOIN financial_loans l ON c.customer_id = l.customer_id
JOIN financial_rates r ON l.term = r.term AND r.loan_type = 'mortgage'
WHERE c.risk_weighting > 7
  AND l.status = 'approved'
  AND (l.interest_rate - r.interest_rate) > 1.0
ORDER BY rate_gap DESC
LIMIT 5
```

**Talking point:** "This SQL joins Oracle CRM, the Loan Origination System (Oracle), and a live Market Rates REST API in a single query — all through Denodo's virtual schema. Without Denodo, your data team builds a pipeline to copy this into Snowflake: weeks of work, and the rate data is stale by the time the pipeline runs. With Denodo: one tool call, live data, instant answer."

---

## Key Messages

1. **MCP Moat**: "Oracle, SQL Server, PostgreSQL, Snowflake, and your external APIs have no native MCP. Denodo exposes all of them through one endpoint. One protocol. Every source. And it extends to any system Denodo connects to — Bloomberg, FiServ, mainframes, SaaS APIs."

2. **Real-Time**: "Snowflake and Databricks require data movement before you can query it. Denodo virtualizes data where it lives — no ETL, no copy, no pipeline. Every answer in this demo was current at query time."

3. **The Flywheel**: "Without Denodo, the agent is blind to most of the bank's systems. Without the agent, Denodo's data requires SQL expertise. Together: any loan officer gets decision-support-grade intelligence in seconds — and every response shows exactly which systems were queried."
