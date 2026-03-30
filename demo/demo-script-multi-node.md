# Demo Script - Multi-Node Loan Workflow

## Setup Checklist

- [ ] Denodo MCP server is running at `http://localhost:8080/verticals/mcp`
- [ ] n8n is running at `http://localhost:5678`
- [ ] Open the workflow at [http://localhost:5678/workflow/lM6azNe4F0EXjKHB](http://localhost:5678/workflow/lM6azNe4F0EXjKHB)
- [ ] Workflow is active
- [ ] OpenAI credential is configured on the workflow
- [ ] Denodo MCP credential is configured on the shared MCP node
- [ ] Chat UI is open from the workflow page
- [ ] Keep this SQL file ready for the last step:
      `demo/multi-tree-flow-data-fixes.sql`

---

## What You Are Testing

This workflow has one chat entry point, but it routes into three different branches:

- `new_loan`
- `existing_loan`
- `compliance`

Those branches should land on these terminal nodes:

- `Risk Synthesizer`
- `Flag for Human Review`
- `Loan Status OK`
- `Escalate to Collections`
- `Compliance Cleared`
- `File SAR Report`

Right now, the data needs one cleanup patch and two explicit scenario patches to make the demo deterministic from the data. The most important dedicated post-patch outcome is:

- `File SAR Report`

---

## The Story

> "This is not one generic assistant. A single chat request gets classified and routed into the right financial workflow. Underwriting goes through credit, payment, and collateral analysis. Existing-loan questions go to servicing. AML questions go to compliance."

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

> "This is the full positive underwriting path. The workflow is combining creditworthiness, payment behavior, and collateral quality before issuing a decision brief."

---

## Question 2 - New Loan Negative Path

**What to say:** "Now let's use a customer with clear risk signals."

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

> "This is the same workflow path, but with different evidence. Instead of a clean approval-style result, the branch escalates to human review because the combined risk is too high."

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

> "Same entry point, different branch. This time the workflow recognized it as a servicing question and routed to the servicing agent instead of the underwriting chain."

---

## Question 4 - Existing Loan Escalation Path

**What to say:** "Now let's force a delinquency-style servicing outcome."

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
- after patch, that loan should be explicitly `defaulted`

**What to say after the result:**

> "This is the negative servicing path. The workflow sees an active loan with no payment history and escalates instead of clearing the account."

---

## Question 5 - Compliance Clear Path

**What to say:** "Now let's move into the compliance branch."

**Type in chat:**
```text
Run AML review for customer 10033
```

**What should happen:**

- Routes to `compliance`
- Runs `AML/KYC Agent`
- Best expected outcome is `Compliance Cleared`

**Why this customer is the best current candidate:**

- James Howard (`10033`)
- risk weighting `1`
- complaint count `0`
- transcript count `0`

**What to say after the result:**

> "This is the clean compliance path. The workflow is looking for suspicious-activity signals, complaint flags, and regulatory red flags, and in this case it should clear the customer."

---

## The Honest Gap

**What to say before the final test:**

> "At this point we have exercised five of the six terminal outcomes. The remaining path is a true SAR case. The workflow is already built for it, but the current data does not yet provide a strong guaranteed suspicious-activity scenario."

---

## Apply the Data Patch

Use:

- [multi-tree-flow-data-fixes.sql](C:/Senthil/Projects/github-projects/agentic-ai-financial/demo/multi-tree-flow-data-fixes.sql)

What this patch now does:

- restores Robert Logan (`10117`) if the earlier compliance patch was already applied
- makes Jane Doe (`20000`) an explicit servicing-negative customer by marking loan `20001` as `defaulted`
- creates Daniel Mercer (`21001`) as the dedicated compliance-negative customer

**What to say while applying it:**

> "This is a useful distinction: the workflow is not the limitation here. The data realism is. We are patching the Denodo-backed demo data so the compliance branch has evidence strong enough to justify a SAR outcome."

---

## Question 6 - Compliance SAR Path

**What to say:** "Now let's re-run compliance with the patched suspicious-activity customer."

**Type in chat:**
```text
Run AML review for customer 21001
```

**What should happen after patch:**

- Routes to `compliance`
- Runs `AML/KYC Agent`
- Ends at `File SAR Report`

**What to say after the result:**

> "Now the workflow has the evidence it needs. The branch is unchanged, but the data now clearly supports a suspicious-activity determination, so the workflow files a SAR report."

---

## Recommended Demo Order

1. `Analyze customer 18926 for loan eligibility`
2. `Analyze customer 10117 for loan eligibility`
3. `Check payment status for customer 18926`
4. `Check payment status for customer 20000`
5. `Run AML review for customer 10033`
6. Explain the compliance-negative data gap
7. Apply `demo/multi-tree-flow-data-fixes.sql`
8. `Run AML review for customer 21001`

---

## Quick Reference

| Prompt | Expected branch | Expected terminal node |
|---|---|---|
| `Analyze customer 18926 for loan eligibility` | `new_loan` | `Risk Synthesizer` |
| `Analyze customer 10117 for loan eligibility` | `new_loan` | `Flag for Human Review` |
| `Check payment status for customer 18926` | `existing_loan` | `Loan Status OK` |
| `Check payment status for customer 20000` | `existing_loan` | `Escalate to Collections` |
| `Run AML review for customer 10033` | `compliance` | `Compliance Cleared` |
| `Run AML review for customer 21001` | `compliance` | `File SAR Report` after patch |

---

## If You Want The Short Version

If you only want a fast 3-minute demo, use these four prompts:

1. `Analyze customer 18926 for loan eligibility`
2. `Analyze customer 10117 for loan eligibility`
3. `Check payment status for customer 20000`
4. `Run AML review for customer 21001` after applying the SQL patch
