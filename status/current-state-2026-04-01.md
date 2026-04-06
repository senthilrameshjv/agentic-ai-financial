# Current State - 2026-04-01

## Summary

This repo currently has three main multi-tree workflow exports:

- original baseline:
  - `workflows/Loan Agent Flow - Multi-Tree with same MCP and openAI model.json`
- compliance-enhanced fork:
  - `workflows/Loan Agent Flow - Multi-Tree with same MCP and openAI model - v2.json`
- investigation-enhanced fork:
  - `workflows/Loan Agent Flow - Multi-Tree with same MCP and openAI model - v3.json`

The baseline export remains the original working reference.

`v2` adds explicit use of:

- `customer_complaints`
- `officer_transcripts`

inside the compliance branch.

`v3` adds a fourth branch:

- `investigation`

That branch is intended for topic-led queries without a customer id and is designed to resolve related customers, loans, and officers from complaint/transcript evidence.

## Important Technical Correction

The current Denodo vector-search behavior is:

- use `vector_distance("embedding", 'input text')`

Do **not** wrap the input text in `embed_ai(...)` at query time for the investigation branch.

Write-time inserts still use `embed_ai(...)` to populate the stored embedding columns where supported.

Current repo docs were updated to reflect this:

- `README.md`
- `SETUP-MULTI-NODE.md`
- `demo/demo-script-multi-node-v2.md`

## Demo / Setup Docs

Current canonical live docs:

- `SETUP-MULTI-NODE.md`
- `demo/demo-script-multi-node-v2.md`
- `README.md`
- `views.md`

Archived local-only docs and older demo scripts were moved to:

- `demo/archive/`
- `docs/archive/`

Those archive folders are ignored in Git.

The intended active demo script is:

- `demo/demo-script-multi-node-v2.md`

Even though its name says `v2`, it now covers the `v3` investigation scenario as well.

## Current Git State

Branch:

- `master`

Recent committed work:

- `7e1600d` Consolidate live workflow docs and archive stale variants
- `17afef9` Add complaint-aware and investigation workflow variants

## Current Uncommitted / Local State

At the time of writing, there are local uncommitted changes in:

- `AGENTS.md`
- `workflows/Loan Agent Flow - Multi-Tree with same MCP and openAI model - v3.json`

There are also local untracked items such as:

- `.omx/`
- `CLAUDE.md.example`

The important one for workflow continuation is:

- `workflows/Loan Agent Flow - Multi-Tree with same MCP and openAI model - v3.json`

The user explicitly stated that they updated `v3` to use the correct Denodo vector syntax:

- `vector_distance(embedding_column, 'input_text')`

So if another session resumes from here, it should treat the local `v3` JSON as newer than the last committed version until reviewed/committed.

## Known Workflow Shape

### Baseline / v2 shared branches

- `new_loan`
- `existing_loan`
- `compliance`

### v3 additional branch

- `investigation`

The investigation branch was added as:

- `Investigation Search Agent`
- `Rank Investigation Matches`
- `Investigation Enrichment Agent`
- `Return Investigation Results`

It also uses:

- `MCP Client - Investigation`

and is routed from the main `Intent Router` and `Flow Router Switch`.

## Known Practical Risk

Broad vector queries against Denodo timed out during direct MCP probing in this environment.

That means:

- prompt-level narrowing still matters
- the `v3` investigation branch may need narrower queries, better filtering, or staged retrieval if runtime behavior is slow

The corrected query syntax is now understood, but real n8n execution of the investigation branch should still be validated interactively.

## Best Next Steps

1. Review local diff for `workflows/Loan Agent Flow - Multi-Tree with same MCP and openAI model - v3.json`
2. If correct, update any remaining wording inside the workflow prompt text if needed
3. Import `v3` into n8n
4. Test these prompts:
   - `Find customers complaining about high mortgage rates`
   - `Show suspicious source of funds cases`
5. If the branch behaves correctly, commit and push the updated `v3` JSON plus the doc note changes from today

## Good Resume Context

If resuming from a new session, start by checking:

- `git status --short`
- `workflows/Loan Agent Flow - Multi-Tree with same MCP and openAI model - v3.json`
- `demo/demo-script-multi-node-v2.md`
- `SETUP-MULTI-NODE.md`

The key fact to preserve is:

- Denodo query-time vector search uses plain text in `vector_distance`, not `embed_ai(...)`
