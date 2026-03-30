# Demo Script - Multi-Node Loan Flow

## Goal

Demonstrate that the live n8n workflow at `http://localhost:5678/workflow/lM6azNe4F0EXjKHB` can route across all three branches and reach all six terminal outcomes, while also showing the one current data gap and how the Denodo-view SQL patch closes it.

## What This Demo Proves

- One chat entry point can route into three distinct workflows:
  - `new_loan`
  - `existing_loan`
  - `compliance`
- The workflow uses specialized agents instead of one general-purpose agent:
  - `Credit Analyst`
  - `Payment History Analyst`
  - `Property Analyst`
  - `Risk Synthesizer`
  - `Loan Servicing Agent`
  - `AML/KYC Agent`
- The current dataset already supports 5 of the 6 terminal outcomes.
- The only explicit gap is the compliance-negative path, which can be fixed with the SQL in:
  - `demo/multi-tree-flow-data-fixes.sql`

## Current Branch Coverage

| Branch | Terminal node | Customer | Current status |
|---|---|---|---|
| New loan | `Risk Synthesizer` | Randy Spence (`18926`) | Ready |
| New loan | `Flag for Human Review` | Robert Logan (`10117`) | Ready |
| Existing loan | `Loan Status OK` | Randy Spence (`18926`) | Ready |
| Existing loan | `Escalate to Collections` | Jane Doe (`20000`) | Needs SQL patch |
| Compliance | `Compliance Cleared` | James Howard (`10033`) | Likely ready |
| Compliance | `File SAR Report` | Daniel Mercer (`21001`) | Needs SQL patch |

## Data Flow By Branch

### 1. New loan branch

Router path:

`When chat message received -> Extract Input -> Intent Router -> Flow Router Switch -> Credit Analyst -> Set Credit Context -> Payment History Analyst -> Set Payment Context -> Property Analyst -> Set Property Context -> Review Gate -> Risk Synthesizer or Flag for Human Review`

What each node contributes:

- `Credit Analyst`
  - reads customer, loan, and underwriting data
  - produces `CREDIT_ANALYSIS`
- `Payment History Analyst`
  - reads loans and payments
  - produces `PAYMENT_ANALYSIS`
- `Property Analyst`
  - reads property data and calculates LTV
  - produces `PROPERTY_ANALYSIS`
- `Review Gate`
  - checks the combined findings
  - routes to either:
    - `Risk Synthesizer`
    - `Flag for Human Review`

### 2. Existing loan branch

Router path:

`When chat message received -> Extract Input -> Intent Router -> Flow Router Switch -> Loan Servicing Agent -> Servicing Decision -> Loan Status OK or Escalate to Collections`

What the branch does:

- `Loan Servicing Agent`
  - inspects loan status, payment activity, missed-payment pattern, and delinquency signal
  - produces `SERVICING_ANALYSIS`
- `Servicing Decision`
  - routes to:
    - `Loan Status OK`
    - `Escalate to Collections`

### 3. Compliance branch

Router path:

`When chat message received -> Extract Input -> Intent Router -> Flow Router Switch -> AML/KYC Agent -> Compliance Decision -> Compliance Cleared or File SAR Report`

What the branch does:

- `AML/KYC Agent`
  - inspects customer, loan, payment, complaint, and transcript signals
  - produces `COMPLIANCE_ANALYSIS`
- `Compliance Decision`
  - routes to:
    - `Compliance Cleared`
    - `File SAR Report`

## Setup Checklist

- n8n is running at [http://localhost:5678/workflow/lM6azNe4F0EXjKHB](http://localhost:5678/workflow/lM6azNe4F0EXjKHB)
- Denodo MCP is reachable at `http://localhost:8080/verticals/mcp`
- The live workflow has the OpenAI credential configured
- The workflow uses the current shared `OpenAI Chat Model` and shared `MCP Client`
- You have the SQL patch file ready:
  - `demo/multi-tree-flow-data-fixes.sql`

## Pre-Demo Notes

The current audit shows:

- Randy Spence (`18926`) is the best clean happy-path customer.
- Robert Logan (`10117`) is the best negative underwriting customer.
- Jane Doe (`20000`) is the best servicing-escalation customer once loan `20001` is patched to an explicit `defaulted` status.
- James Howard (`10033`) is the best compliance-clear customer currently in the dataset.
- The strongest missing scenario is a guaranteed `SAR_REQUIRED` case with a dedicated customer that does not interfere with underwriting tests.

## Demo Sequence

### Step 1. Show the router behavior

Say:

> This flow is not one linear chatbot. It first classifies the request into new-loan analysis, existing-loan servicing, or compliance review, and then routes to a different specialist path.

### Step 2. Run the happy-path new loan flow

Prompt:

```text
Analyze customer 18926 for loan eligibility
```

What to narrate:

- The message routes into the `new_loan` branch.
- `Credit Analyst` should find Randy's approved loan `13147` and strong underwriting.
- `Payment History Analyst` should see deep payment history.
- `Property Analyst` should see acceptable collateral coverage.
- The branch should pass the review gate and continue to `Risk Synthesizer`.

Expected outcome:

- terminal node: `Risk Synthesizer`
- expected business result: approval-style decision brief

Data signals behind this path:

- customer `18926`
- loan `13147`
- credit score `773`
- financial history `Excellent`
- property value `477193.03`
- payment count `69`

### Step 3. Run the negative new loan flow

Prompt:

```text
Analyze customer 10117 for loan eligibility
```

What to narrate:

- This still routes into `new_loan`, but the facts are different.
- Robert has high risk weighting, weak credit, and a poor financial-history signal.
- The analyst chain should accumulate enough concern to fail the review gate.

Expected outcome:

- terminal node: `Flag for Human Review`
- expected business result: refer/decline-style risk outcome

Data signals behind this path:

- customer `10117`
- loan `7581`
- risk weighting `9`
- credit score `575`
- financial history `Poor`
- implied high LTV from `593175.40` loan amount vs `328805.62` property value

### Step 4. Run the positive servicing flow

Prompt:

```text
Check payment status for customer 18926
```

What to narrate:

- This prompt should route to `existing_loan`.
- `Loan Servicing Agent` should use the approved loan and payment history to determine the account is not delinquent.

Expected outcome:

- terminal node: `Loan Status OK`
- expected business result: clear or monitor, but not escalation

Data signals behind this path:

- customer `18926`
- approved loan with extensive payment history
- no obvious delinquency trigger

### Step 5. Run the negative servicing flow

Prompt:

```text
Check payment status for customer 20000
```

What to narrate:

- This also routes to `existing_loan`.
- Jane Doe is the deliberately sharp contrast case.
- After the data patch, her servicing loan is explicitly `defaulted`, which should drive the branch into escalation from the data itself.

Expected outcome:

- terminal node: `Escalate to Collections`
- expected business result: delinquency escalation

Data signals behind this path:

- customer `20000`
- loan `20001`
- after patch, status `defaulted`

### Step 6. Run the positive compliance flow

Prompt:

```text
Run AML review for customer 10033
```

What to narrate:

- This routes to the `compliance` branch.
- James Howard is the low-friction customer with no complaint or transcript noise in the current audit.
- This is the best current candidate to demonstrate a clean AML/KYC clearance.

Expected outcome:

- terminal node: `Compliance Cleared`
- expected business result: no SAR triggers detected

Data signals behind this path:

- customer `10033`
- risk weighting `1`
- complaint count `0`
- transcript count `0`

### Step 7. Call out the current data gap honestly

Say:

> At this point we have demonstrated five of the six terminal outcomes with current data. The remaining gap is the compliance-negative path. The workflow is ready, but the dataset does not yet provide a strong guaranteed SAR scenario.

### Step 8. Apply the patch for the compliance-negative path

Use:

- `demo/multi-tree-flow-data-fixes.sql`

What the patch is designed to do:

- restore Robert Logan (`10117`) if the earlier compliance patch was already applied
- make Jane Doe (`20000`) an explicit servicing-negative customer
- create Daniel Mercer (`21001`) as the dedicated `SAR_REQUIRED` customer

### Step 9. Re-run the compliance-negative flow

Prompt:

```text
Run AML review for customer 21001
```

Expected outcome after patch:

- terminal node: `File SAR Report`
- expected business result: suspicious activity report generated

What to narrate:

- The branch is the same as before.
- What changed is the evidence available through Denodo.
- This shows the workflow logic was not the blocker; the data realism was.

## Suggested Presenter Talk Track

### Opening

> This workflow behaves like a multi-team financial operations process. A single chat input is classified and routed into either underwriting, servicing, or compliance, and each branch uses specialist agents with shared access to live Denodo data.

### After the first new-loan run

> Here the system goes through credit, payment, and collateral analysis before making a decision. That is a true multi-node reasoning chain, not a single model producing a generic answer.

### After the servicing runs

> The same entry point can pivot from origination to servicing simply by changing the prompt intent. We are not building separate apps for each use case; we are routing through one orchestrated workflow.

### During the compliance section

> This is also where the demo becomes useful as a data-quality exercise. The workflow is capable of filing a SAR, but today the data only weakly supports that case. That gives us a very clear next step: patch the data through Denodo views and then rerun the same workflow unchanged.

## Recommended Order For A Live Demo

1. `Analyze customer 18926 for loan eligibility`
2. `Analyze customer 10117 for loan eligibility`
3. `Check payment status for customer 18926`
4. `Check payment status for customer 20000`
5. `Run AML review for customer 10033`
6. Explain the compliance-negative gap
7. Apply `demo/multi-tree-flow-data-fixes.sql`
8. `Run AML review for customer 21001`

## Fallback Notes

- If `Compliance Cleared` for `10033` does not land cleanly on the first try, frame it as:
  - the best current low-risk candidate from the audit
  - still subject to the agent's final interpretation of live records
- If you want a shorter demo, skip the positive servicing run and keep:
  - one new-loan positive
  - one new-loan negative
  - one servicing negative
  - one compliance positive
  - one compliance negative after patch

## Reference Files

- plan: `docs/testing-and-gap-analysis.md`
- audit note: `docs/multi-tree-flow-gap-analysis.md`
- SQL patch: `demo/multi-tree-flow-data-fixes.sql`
- workflow reference: `workflows/Loan Agent Flow - Multi-Tree with same MCP and openAI model.json`
