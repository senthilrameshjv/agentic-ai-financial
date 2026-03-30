# Multi-Tree Flow Gap Analysis

## Summary

A read-only audit was run against the Denodo MCP endpoint used by the live n8n workflow at:

- `http://localhost:5678/workflow/lM6azNe4F0EXjKHB`

The goal was to determine whether the current dataset can drive all six terminal outcomes in the multi-tree workflow and to identify the minimum SQL patch set needed to guarantee coverage without overloading the same customer across unrelated branches.

## Audit Method

- MCP endpoint used for discovery and validation:
  - `http://localhost:8080/verticals/mcp`
- View definitions referenced from:
  - `views.md`
- Existing repo inputs referenced:
  - `scripts/find-demo-customers.js`
  - `scripts/data-gap-analysis.md`
  - `demo/data-setup.sql`
- Focused audit helper:
  - `scripts/audit-multi-tree-coverage.js`

## Current Coverage Matrix

| Branch | Terminal outcome | Candidate | Status | Notes |
|---|---|---|---|---|
| New loan | `Risk Synthesizer` | Randy Spence (`18926`) / loan `13147` | Covered | Strong underwriting, property support, deep payment history |
| New loan | `Flag for Human Review` | Robert Logan (`10117`) / loan `7581` | Covered | High risk weighting, weak credit, poor financial history, high implied LTV |
| Existing loan | `Loan Status OK` | Randy Spence (`18926`) / loan `13147` | Covered | Approved loan with deep payment history |
| Existing loan | `Escalate to Collections` | Jane Doe (`20000`) / loan `20001` | Needs data patch | Make the loan explicitly `defaulted` so the negative servicing outcome is driven by data |
| Compliance | `Compliance Cleared` | James Howard (`10033`) | Likely covered | Low-risk customer with no complaint or transcript noise |
| Compliance | `File SAR Report` | Daniel Mercer (`21001`) | Needs data patch | Dedicated compliance-negative customer avoids interfering with other branches |

## Important Findings

### 1. Happy-path underwriting is already strong

The cleanest current new-loan positive customer is:

- `18926` - Randy Spence
- loan `13147`
- status `approved`
- credit score `773`
- financial history `Excellent`
- property value `477193.03`
- payment count `69`

This customer is a strong fit for:

- `new_loan -> Risk Synthesizer`
- `existing_loan -> Loan Status OK`

### 2. Robert Logan should stay isolated to underwriting-negative

The strongest current new-loan negative customer is:

- `10117` - Robert Logan
- loan `7581`
- risk weighting `9`
- credit score `575`
- financial history `Poor`
- property value `328805.62`
- loan amount `593175.40`

This is already enough to drive:

- weak credit
- elevated risk
- very high implied LTV

That makes Robert the best dedicated fit for:

- `new_loan -> Flag for Human Review`

### 3. Servicing-negative should be explicit in the data

Jane Doe (`20000`) is still the best servicing-negative customer candidate, but the current data is too ambiguous:

- loan `20001`
- status `active`
- payment count `0`

That leaves too much interpretation to the agent. The better data-driven approach is:

- keep Jane as the servicing-negative customer
- update loan `20001` to `defaulted`

This lets the workflow rely on explicit loan status rather than a prompt-specific inference about missing payments.

### 4. Compliance-negative should have its own customer

The earlier approach reused Robert Logan for compliance-negative by adding extra active loans and suspicious complaint/transcript data. That created cross-branch contamination:

- underwriting-negative became less clean to test
- multi-loan behavior started affecting the new-loan branch

The cleaner approach is to create a dedicated compliance-negative customer instead.

### 5. Compliance-positive is likely already available

James Howard (`10033`) remains the best low-risk compliance-clear candidate because the audit shows:

- risk weighting `1`
- complaint count `0`
- transcript count `0`

This should make him the best current candidate for:

- `compliance -> Compliance Cleared`

## Dataset Gaps

### Gap 1: Servicing-negative is not explicit enough

The current servicing-negative case depends on interpretation of:

- `active` loan
- zero payments
- unknown last payment date

To make the branch deterministic from data, the loan itself should carry an explicit delinquent/defaulted state.

### Gap 2: Compliance-negative needs a dedicated scenario

There is still no clean, isolated customer whose data clearly supports:

- multiple active loans
- high risk weighting
- low income band
- suspicious complaint text
- suspicious transcript text

### Gap 3: Underwriting coverage remains sparse overall

Only a minority of loans have underwriting records, so many otherwise usable customers cannot support the new-loan decision path cleanly.

This does not block minimal branch coverage, but it limits flexibility for future demos.

## Minimal Patch Recommendation

Use the SQL in:

- `demo/multi-tree-flow-data-fixes.sql`

That patch now follows this strategy:

- restore Robert Logan to a clean underwriting-negative scenario if the earlier compliance patch was already applied
- make Jane Doe an explicit servicing-negative case by updating loan `20001` to `defaulted`
- create Daniel Mercer (`21001`) as a dedicated compliance-negative customer

## Recommended SQL Changes

The companion patch now does three things:

### 1. Optional cleanup for Robert Logan

If the earlier patch was already run, restore Robert so he stays dedicated to:

- `new_loan -> Flag for Human Review`

### 2. Explicit servicing-negative data for Jane Doe

Update:

- loan `20001`

to:

- `status = 'defaulted'`

so the servicing branch can escalate based on explicit data.

### 3. Dedicated compliance-negative customer

Create:

- Daniel Mercer (`21001`)

with:

- risk weighting `9`
- income band `Low`
- two active loans
- suspicious complaint text
- suspicious transcript text

This keeps:

- `10117` for underwriting-negative
- `21001` for compliance-negative

## Verification Queries

The companion SQL file includes verification queries for:

- Robert Logan restoration checks
- Jane Doe servicing-negative checks
- Daniel Mercer compliance-negative checks

## Suggested Test Prompts

### New loan positive

`Analyze customer 18926 for loan eligibility`

### New loan negative

`Analyze customer 10117 for loan eligibility`

### Existing loan positive

`Check payment status for customer 18926`

### Existing loan negative

`Check payment status for customer 20000`

### Compliance positive

`Run AML review for customer 10033`

### Compliance negative

`Run AML review for customer 21001`

## Recommended Next Step

Apply the SQL in:

- `demo/multi-tree-flow-data-fixes.sql`

Then re-run:

- `node scripts/audit-multi-tree-coverage.js`

and validate the six prompts in the live n8n chat workflow.
