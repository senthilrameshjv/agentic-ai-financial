# Test Plan — Loan Officer Intelligence Assistant

## Test Customer: Robert Logan (ID: 10117)

| Data Point | Expected Value |
|---|---|
| Loyalty | Platinum |
| Income band | Mid-High |
| risk_weighting | 9 |
| Accounts | Savings ($7,722.84), Checking ($1,975.32) |
| Approved loan | loan_id=7581, $593,175 @ 5.5%, 15yr term |
| Rejected loan | loan_id=9195, $501,340 @ 4.5%, 30yr term (should be excluded from risk analysis) |
| Credit score | 575 (loan_id=7581) |
| Market rate (15yr) | 3.75% |
| Refinancing gap | 1.75% (5.5% − 3.75%) |
| Complaints | 10 |
| Transcripts | 4 (2 modification, 2 phone) |

---

## Scenario 1 — Basic Profile Lookup

**Input:**
```
Find Robert Logan and show me his profile and account balances.
```

**Expected tool calls:**
1. `denodo_verticals_query_financial_customers` — resolves "Robert Logan" to customer_id=10117
2. `denodo_verticals_query_financial_acct` or SQL — fetches accounts for customer_id=10117

**Expected output must include:**
- [ ] Full name: Robert Logan
- [ ] Loyalty classification: Platinum
- [ ] Income band: Mid-High
- [ ] Savings account: ~$7,722
- [ ] Checking account: ~$1,975
- [ ] No fabricated data

**Pass criteria:** All checkboxes above satisfied. No hallucinated account types or balances.

---

## Scenario 2 — Default Risk Analysis

**Input:**
```
Is Robert at risk of defaulting on any of his loans?
```

**Expected tool calls:**
1. Customer lookup → customer_id=10117
2. `denodo_verticals_run_sql_query` — loans for customer_id=10117
3. Payments for loan_id=7581
4. Underwriting for loan_id=7581 (or via SQL join)

**Expected output must include:**
- [ ] Finds the approved loan (loan_id=7581, $593K @ 5.5%, 15yr)
- [ ] Does NOT flag rejected loan (loan_id=9195) as a risk
- [ ] Flags **Credit Risk**: credit_score = 575 (below 620 threshold)
- [ ] Flags **High-Risk Customer**: risk_weighting = 9 (above 7 threshold)
- [ ] Provides a clear risk verdict (yes, at risk / moderate risk)

**Pass criteria:** Both risk signals present. Rejected loan not included in analysis.

**Known fix applied:** System prompt updated so agent queries loans with `status = "approved"` only (previously said "active/open" which didn't match the "approved" value in the database).

---

## Scenario 3 — Full Pre-Meeting Briefing

**Input:**
```
Prepare a full pre-meeting briefing for my meeting with Robert Logan tomorrow.
```

**Expected tool calls (9–10 total):**
1. Customer lookup → customer_id=10117
2. Accounts
3. Loans (all)
4. Payments for approved loan (loan_id=7581)
5. Underwriting for loan_id=7581
6. Property for property_id on loan 7581
7. Financial rates (term=15)
8. SQL: complaints WHERE customer_id=10117
9. SQL: transcripts WHERE customer_id=10117

**Expected output sections:**

- [ ] **Customer Profile** — Platinum, Mid-High, risk_weighting=9, age calculated from DOB
- [ ] **Account Summary** — Savings and Checking with correct balances
- [ ] **Loan Portfolio** — loan 7581 shown ($593K, 5.5%, 15yr, approved); loan 9195 shown as rejected (excluded from risk calc)
- [ ] **Risk Signals**
  - [ ] High-Risk Customer (risk_weighting=9)
  - [ ] Credit Risk (credit_score=575)
- [ ] **Refinancing Opportunity** — 5.5% vs 3.75% market rate (1.75% gap), with estimated monthly savings
- [ ] **Complaint History** — mentions 10 complaints, summarises themes
- [ ] **Meeting History** — mentions 4 transcripts (modification + phone meetings)
- [ ] **Recommended Talking Points** — at least 3 items, grounded in the data above

**Pass criteria:** All sections present, all checkboxes above satisfied, no fabricated data.

---

## Scenario 4 — Portfolio-Level Query (Bonus)

**Input:**
```
Which customers have both a high risk weighting AND the fewest loan payments? Show me the top 5.
```

**Expected tool calls:**
1. `denodo_verticals_run_sql_query` — multi-table SQL joining financial_customers, financial_loans, financial_payments

**Expected output must include:**
- [ ] A table of 5 customers with customer name, risk_weighting, and payment count
- [ ] Robert Logan appears (risk_weighting=9, he has 59 payments — may not be top 5 "fewest")
- [ ] Agent writes valid SQL (not hallucinated column names)

**Pass criteria:** Valid SQL executed, tabular results returned, no error from Denodo.

---

## Regression Checks

After any system prompt or workflow update, re-run these quick checks:

| Check | Command | Pass if |
|---|---|---|
| Customer resolves | `"Look up Robert Logan"` | Returns customer_id=10117 |
| Approved loan found | `"What loans does Robert Logan have?"` | Returns loan 7581 (approved, $593K) |
| Credit score found | `"What is Robert Logan's credit score?"` | Returns 575 |
| Refi gap detected | `"Does Robert have a good interest rate on his mortgage?"` | Mentions 5.5% vs 3.75% market |
| Complaints found | `"Has Robert filed any complaints?"` | Returns 10 complaints |

---

## Known Issues & Fixes Applied

| Issue | Root Cause | Fix |
|---|---|---|
| Agent not finding loans for Scenario 2 | System prompt said "active/open loan" — actual DB status is "approved" | Updated prompt to say `status = "approved"` |
| No high-risk customers in data | risk_weighting max was 5 in source data | Patched Robert Logan to risk_weighting=9 via VQL |
| No credit risk signal | Underwriting records missing for demo customer | Inserted underwriting_id=2001 for loan_id=7581 with credit_score=575 |
| No refinancing opportunity | Max refi gap was 1.0% (rule requires >1.0%) | Updated loan 7581 rate from 4.5% to 5.5% |
