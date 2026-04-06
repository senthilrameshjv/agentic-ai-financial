# Plan: v4 Flow With Denodo AI-SDK RAG MCP

## Summary

Create `workflows/Loan Agent Flow - Multi-Tree with same MCP and openAI model - v4.json` as a fork of `v3` that keeps the deterministic branches and adds one natural-language discovery branch powered by Denodo AI SDK MCP.

The new branch uses a two-step RAG pattern:
1. `metadata_query` to discover likely Denodo views from the user's request
2. `data_query` to answer the request against actual data, including clarification when needed

## Key Changes

- Keep `new_loan`, `existing_loan`, `compliance`, and the current deterministic `investigation` path unchanged.
- Extend the intent router with a new flow for open-ended discovery requests that do not depend on a known `customer_id`.
- Add a new switch branch dedicated to Denodo AI-SDK RAG discovery.
- Add a second MCP client node pointed at the Denodo AI SDK remote MCP endpoint.
  - Assume a configurable HTTP endpoint ending in `/mcp`
  - Assume header-based `Authorization` unless OAuth/DCR is required later
- Add a RAG discovery step that:
  - accepts the raw natural-language request
  - uses `metadata_query` first to identify likely views
  - uses `data_query` second to retrieve the answer
  - avoids direct SQL, vector syntax, or hardcoded `views.md`-driven selection logic
- Add a final formatting step so the branch returns a stable response in n8n.

## Response Contract

The RAG branch returns:

- `RAG_DISCOVERY_RESULTS`
- `user_request`
- `selected_views`
- `clarification_needed`
- `grounded_answer`
- `discovery_note`

Rules:

- `selected_views` comes from `metadata_query` results and uses the returned `tableName` values, with short summaries when useful.
- `clarification_needed` is populated when `data_query` asks a follow-up question before answering.
- `grounded_answer` contains the natural-language answer returned by `data_query`.
- `discovery_note` states that metadata discovery is similarity-based and not exhaustive.
- Do not claim row-level evidence, confidence scores, or exhaustive coverage unless the AI SDK explicitly returns them.

## Demo Behavior

The new branch should show that:

- the user can ask in plain English without a `customer_id`
- Denodo AI SDK can identify likely views dynamically
- Denodo AI SDK can ask for clarification when the request is underspecified
- once clarified, the branch returns a grounded answer through the AI SDK MCP path instead of the deterministic MCP path

Example:

- user asks for `5 highest approved loans with loan ID and customer ID`
- the RAG branch asks for clarification about the filter and ranking metric
- user clarifies `filter by approved, get me largest loan amount`
- the RAG branch returns the top results and the views discovered via `metadata_query`

## Test Plan

- Verify `v4` imports cleanly in n8n.
- Verify existing deterministic routes still behave as in `v3`.
- Verify natural-language discovery prompts route to the new RAG branch.
- Verify the RAG branch works without `customer_id`.
- Verify `metadata_query` results appear in `selected_views`.
- Verify ambiguous prompts produce a clarification response instead of a fabricated answer.
- Verify clarified prompts produce a grounded answer from `data_query`.
- Verify the existing MCP client and the new AI SDK MCP client remain isolated and independently configurable.

## Assumptions

- The Denodo AI SDK MCP endpoint is separate from the current deterministic Denodo MCP endpoint.
- `metadata_query` is a ranked similarity search and must not be presented as exhaustive discovery.
- `data_query` may return a clarification question instead of immediate results.
- `data_query` returns conversational answers, so n8n normalizes the final response shape.
- The goal of `v4` is to showcase RAG-based view discovery and grounded answering, not to replace the current deterministic investigation branch.
