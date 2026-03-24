# Data Gap Analysis — Demo Readiness

## Summary

The dataset had four gaps preventing the three demo scenarios from working convincingly. Three gaps were fixed with targeted patches applied via Denodo VQL Shell. All patches have been confirmed applied.

---

## Gaps Found

### 1. risk_weighting — max value was 5 (needed > 7 for "High Risk" signal)

The entire `financial_customers` table had `risk_weighting` values 1–5. The agent's risk rule triggers at > 7. No customer qualified.

**Impact:** Scenario 2 and 3 — "High-Risk Customer" signal never fired.
**Status: FIXED** — Updated Robert Logan (10117) to `risk_weighting = 9`.

---

### 2. Refinancing gap — max gap was 1.0% (needed > 1.0%)

Best existing gap was exactly 1.0%. Our rule requires `> 1.0%`, so it never triggered.
Robert Logan's approved 15yr loan was at 4.5% vs market 3.75% = 0.75% gap — not enough.

**Impact:** Scenario 3 — "Refinancing Opportunity" signal never fired.
**Status: FIXED** — Updated Logan's loan (loan_id=7581) from 4.5% → 5.5%, giving a 1.75% gap.

---

### 3. Underwriting — only 10% of loans had credit scores (2000 of 20000)

The 2000 underwriting records covered a random subset of loan IDs. Robert Logan had no underwriting at all, so the "Credit Risk" signal (credit_score < 620) could never fire for him.

**Impact:** Scenario 2 and 3 — credit risk signal could not appear for demo customer.
**Status: FIXED** — Inserted underwriting record for Logan's loan (underwriting_id=2001, loan_id=7581, credit_score=575).

---

### 4. No `loan_type` field on `financial_loans`

The `financial_rates` table has a `loan_type` column ("Fixed") but `financial_loans` has no `loan_type` field. Rate matching is only possible by `term`.

**Impact:** Minor — agent cannot label loan type explicitly.
**Status: NOT FIXED** — Term-based join works correctly and is sufficient for the demo. Can revisit for a future version.

---

## Patches Applied

> **VQL Shell notes:**
> - Use the `edw_tpcds` connection (the default connection user lacks write credentials)
> - All table references must be prefixed with the database name: `verticals.<view_name>`

### Patch 1 — Raise risk_weighting

```sql
UPDATE verticals.financial_customers
SET risk_weighting = 9
WHERE customer_id = 10117;
```

### Patch 2 — Create refinancing opportunity

```sql
UPDATE verticals.financial_loans
SET interest_rate = 5.5
WHERE loan_id = 7581;
```

### Patch 3 — Add underwriting with below-threshold credit score

First, confirm the max ID:
```sql
SELECT MAX(underwriting_id) FROM verticals.financial_underwriting;
-- Returns: 2000
```

Then insert:
```sql
INSERT INTO verticals.financial_underwriting
  (underwriting_id, loan_id, credit_score, employment_history, financial_history)
VALUES
  (2001, 7581, 575, 'Stable', 'Poor');
```

---

## Demo Customer: Robert Logan (ID: 10117)

| Field | Before Patch | After Patch |
|---|---|---|
| risk_weighting | 4 | **9** |
| credit_score | (none) | **575** |
| loan 7581 interest_rate | 4.5% | **5.5%** |
| Market rate (15yr Fixed) | 3.75% | 3.75% (unchanged) |
| Refinancing gap | 0.75% | **1.75%** ✓ |
| Complaints | 10 | 10 (unchanged) |
| Transcripts | 4 (2 modification, 2 phone) | 4 (unchanged) |
| Loyalty | Platinum | Platinum (unchanged) |
| Income band | Mid-High | Mid-High (unchanged) |

### Risk signals now active

| Signal | Rule | Value |
|---|---|---|
| High-Risk Customer | risk_weighting > 7 | 9 ✓ |
| Credit Risk | credit_score < 620 | 575 ✓ |
| Refinancing Opportunity | loan rate > market rate by > 1% | 1.75% gap ✓ |
| Complaint History | any complaints | 10 complaints ✓ |
| Meeting History | any transcripts | 4 transcripts ✓ |

---

## Demo Questions

```
1. "Find Robert Logan and show me his profile and account balances."

2. "Is Robert at risk of defaulting on any of his loans?"

3. "Prepare a full pre-meeting briefing for my meeting with Robert Logan tomorrow."
```
