# {{CLIENT_SHORT}} — {{CLIENT_NAME}} Salesforce (Accelerize360)

**Read [HANDOFF.md](HANDOFF.md) before doing anything in this project.** It is the full
briefing: orgs, domain model, conventions, the traps that have already cost days, and the live
state of every ticket. This file is only the part that must be in context from the first turn.

Ticket-driven Salesforce work. Tickets are keyed `{{TICKET_KEY}}-###`; each one gets a spec in
`docs/`. <!-- TODO: which cloud (Sales / Service / Nonprofit / ...) and where the logic mostly
lives — flows or Apex. -->

## ⛔ Non-negotiables

- **Pass an explicit, quoted `--target-org` on every `sf` command**, including read-only
  queries. The CLI's aliases are machine-wide and span every client you have ever logged in to;
  a wrong or omitted alias deploys into another company's org and nothing in the output says so.
- **Aliases:** `{{DEV_ALIAS}}` → `{{UAT_ALIAS}}` → `{{PROD_ALIAS}}`. That is also the promotion
  order. Nothing is promoted without having landed and passed its tests in the environment
  before it. Generic aliases (`UAT`, `Dev`, `DevOrg`, …) belong to other engagements.
- **The project default org is `{{DEV_ALIAS}}`** (`.sf/config.json`). Never point it at
  production.
- **Run `sf` from PowerShell, not Bash** — an argument containing a space dies with
  `'C:\Program' is not recognized`.
- **A deploy that ends with `Missing message metadata.transfer:Finalizing` SUCCEEDED.** It is a
  CLI locale bug. Confirm with `sf project deploy report --job-id <id> --json`; do not re-deploy.
- **A green deploy does not mean the feature is live.** Page placement, permission-set
  assignment and flow activation are manual per-environment admin steps. Before reporting
  anything as delivered, say which manual steps are still outstanding in which org.
- **Retrieve into a scratch folder and diff before overwriting anything in `force-app/`.** The
  orgs drift from the repo and from each other.
- **Production deploys use `--test-level RunSpecifiedTests`** naming the covering test class.

## Skills

- `diagnose` — establishing a defect's mechanism before proposing a fix. Loads on a bug report,
  an error email, or anything intermittent. Fires before `spec` and before `deploy`.
- `deploy` — org aliases, promotion path, deploy mechanics. Loads on any deploy/retrieve/test.
- `spec` — the `docs/{{TICKET_KEY}}-###` document format, including the per-org deployment ledger.
- `platform-soql-query` — SOQL authoring and optimisation.

All are project-scoped in `.claude/skills/`, so **open sessions at this folder**, not a
parent — a session started one level up loads none of them.

## Currently broken

Nothing known yet. <!-- TODO: keep this to the one or two things that are live breakages. -->
