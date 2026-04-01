# Demo Script - Multi-Node Loan Workflow v2 Plus Investigation

## Setup Checklist

- [ ] Denodo MCP server is running at `http://localhost:8080/verticals/mcp`
- [ ] n8n is running at `http://localhost:5678`
- [ ] Import and open the v3 workflow:
      `workflows/Loan Agent Flow - Multi-Tree with same MCP and openAI model - v3.json`
- [ ] Confirm the imported workflow name is:
      `Loan Agent Flow - Multi-Tree with same MCP and openAI model - v3`
- [ ] Workflow is active
- [ ] OpenAI credential is configured on the workflow
- [ ] Denodo MCP credential is configured on the shared MCP node
- [ ] Chat UI is open from the workflow page

---

## What Changed

This version keeps the original three routed branches:

- `new_loan`
- `existing_loan`
- `compliance`

The `v2` enhancement is in the `compliance` branch:

- the `AML/KYC Agent` now explicitly queries:
  - `customer_complaints`
  - `officer_transcripts`
- those views are used as evidence for:
  - `sar_trigger`
  - `sar_reasons`
  - `compliance_verdict`

The rest of the workflow is intentionally unchanged:

- same router
- same loan-analysis chain
- same servicing branch
- same `SAR Trigger Check`
- same terminal nodes

The `v3` enhancement adds a fourth branch:

- `investigation`

This branch accepts topic-led prompts without a customer id and tries to resolve the most relevant customers from complaint and transcript evidence using vector search over the embedding columns.

---

## The Story

> "This workflow behaves like a multi-team financial process. One chat request is classified and routed into underwriting, servicing, compliance, or investigation. The compliance branch uses complaints and officer transcripts directly for SAR decisions, and the investigation branch can work backward from a topic or signal to the most relevant customers."

---

## Question 1 - New Loan Happy Path

**What to say:** "Let's start with a clean underwriting case."

**Type in chat:**
```text
Analyze customer 18926 for loan eligibility
```

**What should happen:**

- Routes to `new_loan`
- Runs:
  - `Credit Analyst`
  - `Payment History Analyst`
  - `Property Analyst`
- Passes the review gate
- Ends at `Risk Synthesizer`

**Why this customer works:**

- Randy Spence (`18926`)
- approved loan `13147`
- credit score `773`
- financial history `Excellent`
- property value `477193.03`
- payment count `69`

**What to say after the result:**

> "This is the positive underwriting path. The workflow combines credit, payment behavior, and collateral quality before producing a decision brief."

---

## Question 2 - New Loan Negative Path

**What to say:** "Now let's use a customer with clear loan-risk signals."

**Type in chat:**
```text
Analyze customer 10117 for loan eligibility
```

**What should happen:**

- Routes to `new_loan`
- Runs the same analyst chain
- Accumulates enough negative signals to fail the review gate
- Ends at `Flag for Human Review`

**Why this customer works:**

- Robert Logan (`10117`)
- risk weighting `9`
- credit score `575`
- financial history `Poor`
- loan amount `593175.40`
- property value `328805.62`

**What to say after the result:**

> "Same branch, same specialist chain, different evidence. The workflow escalates to human review because the combined underwriting signals are too weak."

---

## Question 3 - Existing Loan Positive Path

**What to say:** "Now let's switch from origination into servicing."

**Type in chat:**
```text
Check payment status for customer 18926
```

**What should happen:**

- Routes to `existing_loan`
- Runs `Loan Servicing Agent`
- Ends at `Loan Status OK`

**Why this customer works:**

- approved loan with extensive payment history
- no obvious delinquency signal

**What to say after the result:**

> "Same entry point, different branch. The workflow recognized this as a servicing question and routed to the servicing agent instead of the underwriting chain."

---

## Question 4 - Existing Loan Escalation Path

**What to say:** "Now let's show the negative servicing outcome."

**Type in chat:**
```text
Check payment status for customer 20000
```

**What should happen:**

- Routes to `existing_loan`
- Runs `Loan Servicing Agent`
- Ends at `Escalate to Collections`

**Why this customer works:**

- Jane Doe (`20000`)
- loan `20001`
- current live data shows status `defaulted`
- payment count `0`

**What to say after the result:**

> "This is the delinquency path. The workflow sees explicit default-style servicing evidence in the data and escalates to collections."

---

## Question 5 - Compliance Clear Path

**What to say:** "Now let's move into the compliance branch with a clean customer."

**Type in chat:**
```text
Run AML review for customer 10033
```

**What should happen:**

- Routes to `compliance`
- Runs `AML/KYC Agent`
- The agent checks customer profile plus:
  - `customer_complaints`
  - `officer_transcripts`
- Ends at `Compliance Cleared`

**Why this customer works:**

- James Howard (`10033`)
- risk weighting `1`
- complaint count `0`
- transcript count `0`

**What to say after the result:**

> "This is the clean compliance path in v2. The workflow is now checking both complaint history and meeting-transcript evidence, and in this case both come back empty, so the customer is cleared."

---

## Question 6 - Compliance SAR Path

**What to say:** "Now let's use a customer whose complaints and transcript evidence support a SAR outcome."

**Type in chat:**
```text
Run AML review for customer 21001
```

**What should happen:**

- Routes to `compliance`
- Runs `AML/KYC Agent`
- The agent queries:
  - `financial_customers`
  - `customer_complaints`
  - `officer_transcripts`
- Ends at `File SAR Report`

**Why this customer works:**

- Daniel Mercer (`21001`)
- risk weighting `9`
- income band `Low`
- complaint count `1`
- transcript count `1`
- complaint text indicates objection to source-of-funds verification and intent to split transfers across accounts
- transcript says the customer could not document origin of funds and suggested breaking transfers into smaller amounts to avoid review

**What to say after the result:**

> "This is the key v2 proof point. The workflow is not just using a generic risk profile anymore. It is reading live complaints and officer-transcript evidence through Denodo and using that evidence to justify the SAR decision."

---

## Question 7 - Investigation by Topic

**What to say:** "Now let's use the new investigation branch to work backward from a signal instead of starting with a customer id."

**Type in chat:**
```text
Find customers complaining about high mortgage rates
```

**What should happen:**

- Routes to `investigation`
- Runs:
  - `Investigation Search Agent`
  - `Rank Investigation Matches`
  - `Investigation Enrichment Agent`
- Ends at `Return Investigation Results`

**Why this topic works:**

- complaint and transcript evidence for Jane Doe (`20000`) explicitly mention:
  - mortgage rate dissatisfaction
  - competitor rate offer
  - risk of switching lenders

**What to say after the result:**

> "This is the new scenario. Instead of giving the workflow a customer id, we gave it a business signal. The workflow searched complaint and transcript embeddings, resolved the likely customer, and then enriched the result with customer and loan context."

**Optional second investigation prompt:**
```text
Show suspicious source of funds cases
```

**Best expected customer:**

- Daniel Mercer (`21001`)

**Why it works:**

- complaint and transcript evidence both mention:
  - source-of-funds verification issues
  - multiple external accounts
  - breaking transfers into smaller amounts to avoid review

---

## Recommended Demo Order

1. `Analyze customer 18926 for loan eligibility`
2. `Analyze customer 10117 for loan eligibility`
3. `Check payment status for customer 18926`
4. `Check payment status for customer 20000`
5. `Run AML review for customer 10033`
6. `Run AML review for customer 21001`
7. `Find customers complaining about high mortgage rates`

---

## Quick Reference

| Prompt | Expected branch | Expected terminal node |
|---|---|---|
| `Analyze customer 18926 for loan eligibility` | `new_loan` | `Risk Synthesizer` |
| `Analyze customer 10117 for loan eligibility` | `new_loan` | `Flag for Human Review` |
| `Check payment status for customer 18926` | `existing_loan` | `Loan Status OK` |
| `Check payment status for customer 20000` | `existing_loan` | `Escalate to Collections` |
| `Run AML review for customer 10033` | `compliance` | `Compliance Cleared` |
| `Run AML review for customer 21001` | `compliance` | `File SAR Report` |
| `Find customers complaining about high mortgage rates` | `investigation` | `Return Investigation Results` |

---

## Suggested Presenter Talk Track

### Opening

> "One chat entry point, three specialist branches. Underwriting goes through credit, payment, and collateral analysis. Servicing goes through delinquency logic. Compliance now goes beyond customer master data and uses complaints plus officer transcripts as live evidence."

> "In the newest version, there is also an investigation branch that starts with a signal or topic and resolves the related customer entities from complaint and transcript evidence."

### After the underwriting runs

> "This is not one general-purpose model making up a financial answer. It is a routed workflow with specialist stages and explicit gates."

### During the servicing runs

> "The same entry point can pivot from origination to servicing just by changing intent. That is orchestration, not a monolithic chatbot."

### During the v2 compliance runs

> "The important v2 enhancement is that the compliance agent can now justify its decision with unstructured evidence. A clean customer stays clear because there is no complaint or transcript noise. A suspicious customer escalates because the complaint and transcript record directly support the SAR rationale."

### During the investigation run

> "The investigation branch flips the workflow around. Instead of starting from a known customer, it starts from a business symptom like rate dissatisfaction or suspicious transfer language, searches the complaint and transcript embeddings, and then brings back the most relevant customers with their linked loans and officers."

---

## Notes

- Current live data already supports the v2 compliance-negative scenario with customer `21001`.
- Current live data already shows customer `20000` as `defaulted`, so the servicing-negative case no longer requires a patch first.
- The new investigation scenario is intended for the `v3` workflow, not the `v2` workflow.
- If the imported v2 workflow lands differently in n8n than expected, validate that the `AML/KYC Agent` prompt still contains the appended fields:
  - `complaint_summary`
  - `transcript_flags`
  - `transcript_summary`
