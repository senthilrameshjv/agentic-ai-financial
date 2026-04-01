# Demo Script - Multi-Node Workflow

## Setup Checklist

- [ ] Denodo MCP server is running at `http://localhost:8080/verticals/mcp`
- [ ] n8n is running at `http://localhost:5678`
- [ ] Import and open the current RAG test workflow:
      `workflows/multi-node-with-rag-session-lock-candidate.json`
- [ ] Confirm the imported workflow name is:
      `Multi tree flow with Denodo AI SDK RAG session lock candidate`
- [ ] Workflow is active
- [ ] OpenAI credential is configured on the workflow
- [ ] Denodo MCP credential is configured on the deterministic MCP nodes
- [ ] Denodo AI SDK MCP endpoint is reachable at `http://host.docker.internal:8008/mcp`
- [ ] AI SDK MCP credential/header auth is configured on `MCP Client - AI SDK`
- [ ] Chat UI is open from the workflow page

---

## What This Workflow Covers

This workflow includes:

- `new_loan`
- `existing_loan`
- `compliance`
- `investigation`
- `rag_discovery`

The deterministic branches use the Denodo MCP server directly.
The RAG branch is still a work in progress and is currently being tested for:

- natural-language Denodo AI SDK routing
- follow-up clarification handling
- session-pinned RAG routing
- explicit RAG reset behavior

---

## The Story

> "This workflow behaves like a multi-team financial process. One chat request is classified and routed into underwriting, servicing, compliance, investigation, or a Denodo AI SDK RAG path."

> "The deterministic paths use explicit workflow structure and Denodo queries. The RAG path is the current work in progress: it passes natural-language requests to Denodo AI SDK and is being hardened so follow-up turns stay pinned to RAG until an explicit reset."

---

## Question 1 - New Loan Happy Path

**Type in chat:**
```text
Analyze customer 18926 for loan eligibility
```

**Expected branch:** `new_loan`

**Expected terminal node:** `Risk Synthesizer`

---

## Question 2 - New Loan Negative Path

**Type in chat:**
```text
Analyze customer 10117 for loan eligibility
```

**Expected branch:** `new_loan`

**Expected terminal node:** `Flag for Human Review`

---

## Question 3 - Existing Loan Escalation Path

**Type in chat:**
```text
Check payment status for customer 20000
```

**Expected branch:** `existing_loan`

**Expected terminal node:** `Escalate to Collections`

---

## Question 4 - Compliance SAR Path

**Type in chat:**
```text
Run AML review for customer 21001
```

**Expected branch:** `compliance`

**Expected terminal node:** `File SAR Report`

---

## Question 5 - Investigation by Topic

**Type in chat:**
```text
Find customers complaining about high mortgage rates
```

**Expected branch:** `investigation`

**Expected terminal node:** `Return Investigation Results`

---

## Question 6 - RAG Metadata Discovery

**Type in chat:**
```text
What loan related tables are available
```

**Expected branch:** `rag_discovery`

**Expected terminal node:** `Return RAG Results`

**What this is testing:**

- initial RAG routing
- Denodo AI SDK metadata-style response
- session lock creation for follow-up turns

---

## Question 7 - RAG Clarification Follow-Up

**Type in chat:**
```text
5 highest approved loans with loan ID and customer ID
```

**Expected branch:** `rag_discovery`

**Likely follow-up prompt from the workflow:** clarification about ranking or approval semantics

**Answer with:**
```text
filter by approved, get me largest loan amount
```

**Expected behavior:**

- stays on `rag_discovery`
- does not route to deterministic branches
- returns either another clarification or the grounded answer

---

## Question 8 - RAG Reset

**Type in chat:**
```text
Thanks. Reset RAG
```

**Expected branch:** `rag_end`

**Expected behavior:**

- clears the RAG session lock
- clears chat memory for that session
- returns a response like:
  - `Ok, I reset RAG.`
  - `What do you want to know next?`

**Next prompt after reset:**
```text
Check payment status for customer 18926
```

**Expected behavior after reset:**

- routes fresh from scratch
- can go to deterministic routing again

---

## Quick Reference

| Prompt | Expected branch | Expected terminal node |
|---|---|---|
| `Analyze customer 18926 for loan eligibility` | `new_loan` | `Risk Synthesizer` |
| `Analyze customer 10117 for loan eligibility` | `new_loan` | `Flag for Human Review` |
| `Check payment status for customer 20000` | `existing_loan` | `Escalate to Collections` |
| `Run AML review for customer 21001` | `compliance` | `File SAR Report` |
| `Find customers complaining about high mortgage rates` | `investigation` | `Return Investigation Results` |
| `What loan related tables are available` | `rag_discovery` | `Return RAG Results` |
| `5 highest approved loans with loan ID and customer ID` | `rag_discovery` | `Return RAG Results` |
| `Thanks. Reset RAG` | `rag_end` | `Return RAG End` |

---

## Notes

- This script is aligned with the current cleaned workflow filenames in `workflows/`.
- The RAG branch is still under active validation and should be treated as a test path, not the final stable demo baseline.
- If the RAG follow-up path misroutes again, confirm the workflow execution still has the same `sessionId` and that the session lock store is persisting across turns.
