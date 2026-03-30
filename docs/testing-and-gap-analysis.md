# Testing and Gap Analysis Plan

## Summary

Use the live n8n workflow at `http://localhost:5678/workflow/lM6azNe4F0EXjKHB` as the behavior contract, use the read-only Denodo MCP endpoint at `http://localhost:8080/verticals/mcp` for discovery and validation, and generate SQL that writes through Denodo views such as `verticals.financial_loans` so the underlying SQL Server demo source is updated indirectly through Denodo.

This work has two tracks:

1. **Read-only discovery and validation**
2. **Denodo-view SQL patch generation**

The goal is to guarantee that the current multi-tree workflow has enough data to exercise all six terminal outcomes at least once.

## Workflow Coverage Targets

The current workflow has six terminal outcomes that must each have at least one testable customer:

### New Loan Branch

- `new_loan` -> `Risk Synthesizer`
- `new_loan` -> `Flag for Human Review`

### Existing Loan Branch

- `existing_loan` -> `Loan Status OK`
- `existing_loan` -> `Escalate to Collections`

### Compliance Branch

- `compliance` -> `Compliance Cleared`
- `compliance` -> `File SAR Report`

## Source of Truth

### Behavioral contract

- live workflow: `lM6azNe4F0EXjKHB`
- local export reference:
  - `workflows/Loan Agent Flow - Multi-Tree with same MCP and openAI model.json`

### Data contract

- `views.md`
- workflow agent prompts from the exported n8n workflow

### MCP endpoint

- `http://localhost:8080/verticals/mcp`
- read-only for this exercise

### SQL mutation path

- Denodo views using fully qualified names such as:
  - `verticals.financial_customers`
  - `verticals.financial_loans`
  - `verticals.financial_underwriting`
  - `verticals.financial_payments`
  - `verticals.customer_complaints`
  - `verticals.officer_transcripts`
  - `verticals.financial_rates`

## Discovery Plan

### 1. Build a branch requirement matrix from the live workflow

For each branch, document the exact data prerequisites inferred from the current prompts.

#### New loan positive

Requires:

- customer record
- loan record
- underwriting record
- property record
- usable market rate
- no `WEAK`
- no `High Risk`
- no `INSUFFICIENT_DATA`

#### New loan negative

Requires one or more of:

- weak credit
- high-risk payment pattern
- insufficient data
- high-risk or missing collateral signal

#### Existing loan positive

Requires:

- loan record
- enough payment history to avoid delinquency escalation
- loan output that resolves to `CLEAR` or `MONITOR`

#### Existing loan negative

Requires:

- delinquency evidence strong enough to produce `ESCALATE`
- typically 2+ missed payments or an equivalent default/delinquency signal

#### Compliance positive

Requires:

- customer, loan, and payment context
- no SAR-triggering signal
- output that resolves to `CLEAR`

#### Compliance negative

Requires:

- data or supporting text strong enough to plausibly produce `SAR_REQUIRED`

### 2. Run MCP-based discovery queries

Use MCP only for:

- schema awareness
- candidate search
- max-id lookup
- branch coverage validation

Audit these views:

- `verticals.financial_customers`
- `verticals.financial_loans`
- `verticals.financial_underwriting`
- `verticals.financial_payments`
- `verticals.financial_properties`
- `verticals.financial_rates`
- `verticals.customer_complaints`
- `verticals.officer_transcripts`

### 3. Identify branch blockers

For each terminal branch, mark it as:

- already covered
- nearly covered
- blocked by missing rows
- blocked by weak values
- blocked by weak text signals

## Current Known Findings

These findings are already confirmed from initial MCP inspection and current repo scripts:

### Confirmed strengths

- customer `20000` already exists as a strong, richly populated demo customer
- `customer 20000` currently has:
  - active loan `20001`
  - underwriting record
  - complaint record
  - transcript record
  - mortgage rate support in `financial_rates`
- a mortgage rate row already exists in `financial_rates`

### Confirmed gaps

- most loans do **not** have underwriting coverage
- loan status distribution is heavily concentrated in:
  - `pending`
  - `rejected`
  - `approved`
- only one loan currently has `active`
- therefore servicing-path coverage is likely thin
- most customers do not have complaint or transcript coverage
- refinance/rate-driven and compliance-negative scenarios are not broadly represented

These observations should be converted into a precise branch-by-branch matrix during implementation.

## SQL Patch Strategy

### Rules

- write only through Denodo views
- use fully qualified names with `verticals.*`
- prefer minimal targeted updates over broad normalization
- prefer patching existing customers where possible
- insert new rows only when required to unblock a branch

### Mutation patterns

Allowed examples:

```sql
UPDATE verticals.financial_customers
SET risk_weighting = 9
WHERE customer_id = 10117;
```

```sql
INSERT INTO verticals.financial_loans (
  loan_id, customer_id, loan_amount, interest_rate, term, property_id, loan_officer_id, status, date_created
) VALUES (
  20002, 20001, 250000.00, 8.25, 30, 10, 1001, 'approved', '2026-03-30'
);
```

### Minimal coverage objective

Generate the smallest patch set that guarantees at least one customer for each of:

- `new_loan` positive
- `new_loan` negative
- `existing_loan` positive
- `existing_loan` negative
- `compliance` positive
- `compliance` negative

Customer reuse is allowed only when it keeps each branch easy to test and easy to explain.

## Deliverables

Implementation should produce:

### 1. Gap analysis note

A markdown note that:

- maps each branch to candidate customers
- explains what is missing
- explains what SQL patch will fix it

### 2. SQL patch script

One SQL file that:

- uses `verticals.*`
- groups changes by branch or customer
- includes comments explaining intent

### 3. Verification query block

A query set that can be run after patching to confirm:

- rows exist
- joins resolve correctly
- branch signals are now present

### 4. Test prompt list

One prompt per branch for use in the n8n chat UI.

## Testing Plan

### Pre-patch

1. Run discovery via MCP.
2. Record coverage status for all six terminal outcomes.
3. Capture the exact blockers for each uncovered branch.

### Post-patch

1. Re-run the same MCP audit.
2. Confirm each branch now has at least one viable customer.
3. Confirm all inserted or updated records are visible through Denodo.

### Workflow-level validation

Use the n8n chat UI to test the live workflow with customer-specific prompts and confirm the expected branch terminal result:

- `Risk Synthesizer`
- `Flag for Human Review`
- `Loan Status OK`
- `Escalate to Collections`
- `Compliance Cleared`
- `File SAR Report`

## Implementation Defaults

The implementation should assume:

- MCP is read-only and used only for discovery and validation
- Denodo view writes are supported for the relevant demo views
- the current workflow `lM6azNe4F0EXjKHB` is the canonical workflow under test
- the objective is **minimal branch coverage**, not broad data cleanup
- all generated SQL and verification queries should consistently use `verticals.*`
