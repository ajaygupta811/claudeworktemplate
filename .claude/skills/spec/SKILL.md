---
name: spec
description: Write or update a {{TICKET_KEY}}-### spec document in docs/. Use when starting a Jira story, recording a solution design, or logging what was deployed.
---

# {{CLIENT_SHORT}} spec documents

Specs live in `docs/`, named `{{TICKET_KEY}}-<number>_<Title_In_Underscores>.md` — e.g.
`{{TICKET_KEY}}-101_Delete_Case_And_Related.md`. A story may also carry a `_JiraStory.md` twin
holding the content to paste into Jira; that one is trimmed to **Solution / Components / QA
Testing / Notes for QA** and omits the internal reasoning.

## Section order in the main spec

```
# {{TICKET_KEY}}-### — <Title>

## Why it's needed          the business problem, in the client's terms
## What <the thing> does    behavior, usually a table or list
## <Guard / edge cases>     what is blocked and why (often a follow-up ticket)
### Out of scope            what this deliberately does NOT do
## Components (source-controlled, SFDX)   every metadata file, by path
## Security model           permission set, custom permission, who holds it
## Manual step to finish the rollout (per environment)
## Deployment status
## QA (run in <org>, where <data> exists)
```

Not every section applies to every story, but keep the ones that do in this order — the docs are
read side by side. [docs/_TEMPLATE_Spec.md](../../../docs/_TEMPLATE_Spec.md) is a blank copy.

## Two sections carry more weight than they look

**Manual step to finish the rollout.** Most changes need an admin action the deploy cannot
perform — page layout placement, permission-set assignment, flow activation. Write it per
environment. A feature with an unlisted manual step reads as delivered and is not.

**Deployment status.** A per-org ledger, one bullet each, with the state at the front:

```markdown
- ✅ **{{DEV_ALIAS}}** — Apex + Permission Set + Flow deployed; `MyServiceTest`
  passes 6/6, 93% coverage.
- ⚠️ **{{UAT_ALIAS}}** — guard deployed. Still to do here: end-to-end QA (TC6–TC8) against
  real data, plus the manual page-placement step.
- ✅ **Production ({{PROD_ALIAS}})** — 8 components deployed via `RunSpecifiedTests`;
  tests pass 6/6. **Inert until an admin does the page placement + permission-set
  assignment below** — no button is visible and no one holds the permission yet.
```

Name the test class, its pass count, and coverage. "Deployed" alone is not a status — say what
still blocks a user from using it. Mark partial states as partial rather than green; a ✅ that
hides an outstanding manual step is the thing this ledger exists to prevent.

## QA sections name the org and why

QA is written against a specific sandbox, with the reason: *"run in {{UAT_ALIAS}}, where
<the data this case needs> exists"*. Dev sandboxes often lack the data a test case needs, so
state which org and what data the case depends on. Number test cases `TC1`, `TC2`, … so the
deployment ledger can reference which ones are still outstanding.

## Writing one

Read a sibling spec first and match its level of detail: component lists give full SFDX paths,
and security sections name the actual permission set and custom permission API names.
<!-- TODO: once a story is finished, name it here as the worked example. -->

See [[deploy]] for the org aliases these documents refer to.
