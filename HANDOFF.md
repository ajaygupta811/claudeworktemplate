# {{CLIENT_SHORT}} — Project Handoff

**{{CLIENT_NAME}} Salesforce engagement, delivered by Accelerize360.**
<!-- TODO: date and author of the latest revision. -->

If you are an AI assistant reading this: this document plus `.claude/skills/` is your full
briefing. Read it start to finish before touching an org. If you are a human: sections 1–6 are
the orientation, 7–9 are the parts that will save you a day each, 10 is the live work.

> **Keep this file current.** Sections 1, 4, 6 and 10 start as placeholders. §7 starts with the
> platform traps carried over from earlier engagements — they are Salesforce/CLI behaviour, not
> client facts, so they apply here too. Add this client's own traps below them as you find them.

---

## 1. What this engagement is

<!-- TODO: who the client is, which clouds (Sales / Service / Nonprofit / Experience Cloud),
external integrations, and how work arrives (Jira project key {{TICKET_KEY}}). -->

The work is ticket-driven, keyed **{{TICKET_KEY}}-###**. The job on each ticket: establish the
actual mechanism, write it down as a spec in `docs/`, build it, promote it Dev → UAT → Prod,
and say plainly what still blocks a user from using it.

### The one thing to internalise

**A green deploy routinely ships nothing a user can see.** Page placement, permission-set
assignment and flow activation are manual per-environment admin steps the deploy cannot perform.
Every spec therefore carries a *Manual step to finish the rollout* section and a per-org
*Deployment status* ledger. Keep both honest — a ✅ that hides an outstanding manual step is the
exact failure these documents exist to prevent.

---

## 2. Read in this order

| # | File | Why |
|---|---|---|
| 1 | This file | orientation, traps, live work |
| 2 | `.claude/skills/deploy/SKILL.md` | org aliases and the promotion path — non-negotiable |
| 3 | `.claude/skills/spec/SKILL.md` | how a spec document is structured |
| 4 | `.claude/skills/diagnose/SKILL.md` | how a defect is investigated before it is fixed |
| 5 | <!-- TODO: the fullest worked spec in docs/ --> | |

---

## 3. Machine setup

Everything below is one-time. The repo is self-contained apart from org authentication.

### 3.1 Tooling

- **Salesforce CLI (`sf`)** — https://developer.salesforce.com/tools/salesforcecli
- **Node.js 18+** and `npm install` in the project root (installs Prettier with the Apex and XML
  plugins, ESLint, Jest, husky).
- **VS Code** with the Salesforce Extension Pack. `.vscode/extensions.json` lists the
  recommended set, including `financialforce.lana` (Apex log analyser).
- **Claude Code** — the project skills in `.claude/skills/` load automatically when a session is
  opened **at the project folder**. See §5.

### 3.2 Authenticate the three orgs

Credentials come from Accelerize360 / {{CLIENT_NAME}} — they are not in this repo and must not
be put in it. From PowerShell:

```powershell
sf org login web --alias {{DEV_ALIAS}}  --instance-url https://<mydomain>--dev.sandbox.my.salesforce.com
sf org login web --alias {{UAT_ALIAS}}  --instance-url https://<mydomain>--uat.sandbox.my.salesforce.com
sf org login web --alias {{PROD_ALIAS}} --instance-url https://login.salesforce.com
```

Use exactly these alias spellings. The skills, the specs and every command in this document
refer to them by name.

### 3.3 The default org is the dev sandbox

`.sf/config.json` sets `target-org` to **`{{DEV_ALIAS}}`**. Never change it to production — an
omitted `--target-org` should land somewhere harmless. Passing `--target-org` explicitly every
time is the rule regardless.

### 3.4 Sanity check

```powershell
sf org list
sf org display --target-org {{DEV_ALIAS}}
```

Check the instance URL printed matches the client's My Domain.

---

## 4. Repo map

```
{{CLIENT_SHORT}}/
├── HANDOFF.md            ← this file
├── CLAUDE.md             ← short auto-loaded briefing pointing here
├── .claude/skills/       ← deploy, spec, diagnose, platform-soql-query
├── docs/                 ← one spec per ticket; this is the project's memory
├── force-app/main/default/
├── manifest/package.xml
├── config/project-scratch-def.json
└── scripts/
```

<!-- TODO: once metadata is retrieved, annotate force-app/ — class/test counts, where the
business logic lives, folders that are stock scaffolding and can be ignored. -->

**Retrieve into a scratch folder and diff before overwriting anything in `force-app/`** if the
org may have drifted. Commit before every retrieve so a bad one can be undone.

---

## 5. How Claude is configured here, and how to keep it

Project-scoped skills live in `.claude/skills/` and travel with the folder.

| Skill | Fires on | What it prevents |
|---|---|---|
| `deploy` | any `sf project deploy` / `retrieve` / Apex test run | deploying into the wrong client's org |
| `spec` | writing or updating a `{{TICKET_KEY}}-###` document in `docs/` | shipping a feature whose manual rollout step is unrecorded |
| `diagnose` | a bug report, error email, or anything intermittent | a confident wrong diagnosis built on and deployed |
| `platform-soql-query` | writing or optimising SOQL | slow or unsafe queries |

### ⛔ Open Claude sessions **at the project folder**, not at a parent

Project skills load from the start directory and every parent up to the repo root. A session
started one level up gets **none** of them — and may load another client's instead.

### If you keep your own persistent notes

Write new hard-won traps back into this file (§7) or `.claude/skills/deploy/SKILL.md` rather
than a personal store. A trap recorded only in a personal memory is a trap the next person
inherits blind.

---

## 6. Domain model primer

<!-- TODO: enough to read the specs without guessing — the core objects and how they relate,
which lookups do and do not cascade, status vocabularies that matter (and near-duplicates to
avoid), portals and integrations and what drives them (scheduled job names, cron, timezone). -->

---

## 7. ⛔ Traps that have already cost real time

§7.1–7.8 were found the expensive way on earlier engagements. They are Salesforce and CLI
behaviour, so expect them here. Add client-specific traps as §7.9 onward.

### 7.1 The org alias trap — the worst one

The CLI holds aliases for every client you have logged in to, machine-wide.

- **Nothing in the CLI output names the company**, only the instance URL. A cross-client deploy
  looks exactly like a correct one.
- **Generic aliases** — `UAT`, `Dev4`, `DevOrg` — belong to other engagements. Only the
  `{{CLIENT_SHORT}}` prefix is this client.
- **An alias with a space** must be quoted; unquoted, `sf` reads the first word as the alias.
- **A default org pinned to production** means an omitted flag silently hits production. This
  project pins `{{DEV_ALIAS}}` instead (§3.3).

**Rule: pass an explicit, quoted `--target-org` on every command, and read the instance URL in
the output back against the org you meant.**

### 7.2 On Windows, `sf` lies three ways

- **A successful deploy reports as an error.** The run ends with
  `Error (MetadataTransferError): Metadata API request failed: Missing message
  metadata.transfer:Finalizing for locale en_US` and a non-zero exit. **The deploy has already
  committed.** Scrape the `Deploy ID:` line and confirm with
  `sf project deploy report --job-id <id> --json`.
- **Aggregate SOQL returns blank columns under `--result-format csv`.** Use `--json` and read
  `result.records`.
- **`sf` breaks in a Bash/MSYS shell when an argument contains a space** — dies with
  `'C:\Program' is not recognized`. **Run every `sf` command from PowerShell.**

Also: `AccessLevel.SYSTEM_MODE` / `WITH SYSTEM_MODE` is a **compile error in anonymous Apex**,
so a diagnostic replaying production class logic must have it stripped. And a long-text-area
field **cannot be filtered in SOQL** — narrow it in Apex after the query.

### 7.3 Production refuses to deploy any class a scheduled job references

```
This schedulable class has jobs pending or in progress - CronTrigger IDs (08e...)
```

The bypass is a **three-deploy sequence** — see `.claude/skills/deploy/SKILL.md`. The metadata
member is `Settings:Deployment` (not `Deploy`); put `doesSkipAsyncApexValidation` back afterwards
and re-retrieve to prove it.

### 7.4 Production may deploy flows **inactive**

It is an org setting, and sandboxes often do not share it. A flow deployed to Prod lands as
**Draft**. Activate it with a `flowDefinitions/` deploy setting `activeVersionNumber`.

Related: **the orgs' flows and flexipages drift.** Active flow versions differ per org, and
admins add Prod-only actions and components to record pages. Always retrieve the target org's
own version before editing it.

### 7.5 An Apex DML list holding the same sObject instance twice **throws**

```apex
Database.upsert(recordsToUpsert, false, AccessLevel.SYSTEM_MODE);
// System.ListException: Before Insert or Upsert list must not have two identically equal elements
```

- **`allOrNone = false` does not contain it.** The exception is *thrown*, not returned as a
  per-record error. The whole batch is discarded.
- **Any error-log insert in the same transaction rolls back with it**, so the failure leaves
  nothing to grep. The only surviving evidence is `AsyncApexJob.ExtendedStatus`.
- **A chained Queueable stops dead**, which reads as "the integration stopped running".
- **It can appear to fix itself** when the colliding record ages out of the input window.
- **A routine admin action triggers it** — e.g. an Account merge collapses two external keys
  onto one record, so two payload rows resolve to one sObject instance.

**Rule:** when payload rows resolve to pre-fetched sObjects, keep a `Set<Id> queued` and skip
the second hit — before the field assignments. **When an integration "stops syncing" with an
empty error table, read `AsyncApexJob` first: the absence of logs is itself the signature.**

### 7.6 Never re-create a scheduled job to change its timing

The cron is interpreted in the **running user's** timezone. Re-scheduling under a different user
silently moves the fire time. Scheduled Apex resolves the class at fire time, so a deployed class
change is picked up on the next run without touching the schedule.

### 7.7 `SELECT COUNT(Id) FROM ContentDocument` is sharing-filtered and does not say so

On a previous org it returned **35** as a System Administrator; the real number of
record-linked documents was **99,130**. `ContentVersion` is filtered identically and
"corroborates" the wrong number.

- Size file work from **`ContentDocumentLink` filtered by `LinkedEntityId`**, chunked over
  parent ids. That path is not filtered.
- **Chunk to ~200 ids.** The CLI sends SOQL as a GET query string, so larger chunks fail with
  `URI Too Long` (and Windows argv limits fail first).
- **Every ContentDocument also carries an automatic link to its owning User.** Count links by
  entity type, never by total, in tests.

### 7.8 Validation rules fire on flow-written records, against the *starting* user

`$Profile` / `$Permission` in a validation rule evaluate against whoever began the transaction,
not the flow's system context. A flow that writes across objects in one transaction can be
rolled back entirely by a validation rule on the *second* object. Check every active validation
rule on every object a flow writes to.

<!-- ### 7.9 <client-specific trap> -->

---

## 8. Working conventions

### Spec documents

`docs/{{TICKET_KEY}}-<number>_<Title_In_Underscores>.md`, format per
`.claude/skills/spec/SKILL.md`; blank copy at `docs/_TEMPLATE_Spec.md`.

"Deployed" alone is not a status. Say what still blocks a user. QA sections name the org and the
reason it has the data the test needs.

### Code

- Test classes are `<ClassName>Test.cls`.
- `npm run prettier` and `npm run lint` before committing; husky + lint-staged run on commit.
- Validate before deploying: `sf project deploy start --dry-run --target-org {{DEV_ALIAS}} ...`
- **Write the test against the unfixed baseline first.** Confirm the regression test fails with
  the production error before the fix goes in — otherwise it only proves it passes alongside the
  fix, not that it catches the defect.

---

## 9. Quick command reference

All from PowerShell (§7.2).

```powershell
# dry run
sf project deploy start --dry-run --target-org {{DEV_ALIAS}} --source-dir force-app/main/default/classes/MyService.cls

# sandbox deploy
sf project deploy start --target-org {{UAT_ALIAS}} --source-dir force-app/main/default/classes

# production deploy — always RunSpecifiedTests
sf project deploy start --target-org {{PROD_ALIAS}} --test-level RunSpecifiedTests `
  --tests MyServiceTest --source-dir force-app/main/default/classes

# confirm a deploy that "failed" with the locale error
sf project deploy report --job-id <DeployId> --json

# run a test class
sf apex run test --target-org {{DEV_ALIAS}} --tests MyServiceTest --result-format human --wait 10

# build a manifest from an org, then retrieve it
sf project generate manifest --from-org {{DEV_ALIAS}} --output-dir manifest
sf project retrieve start --target-org {{DEV_ALIAS}} --manifest manifest/package.xml

# query — use --json, not csv, for anything aggregated
sf data query --target-org {{PROD_ALIAS}} --query "SELECT Id FROM Case LIMIT 5" --json
```

---

## 10. Live work

<!-- TODO: state of every ticket in docs/, dated. -->

| Ticket | State | What is outstanding |
|---|---|---|
| | | |

### Decisions that need a client answer

-

### Known environment drift

-

---

## 11. What is deliberately not in this repo

- **Credentials.** No org passwords, tokens or connected-app secrets.
- **Data extracts.** `reports/` is git-ignored — exports contain client PII; never commit them.
- **Jira.** Ticket text and client conversation live there.

---

## 12. First-week checklist

1. Get org credentials; authenticate all three aliases exactly as in §3.2.
2. `npm install`; `git init` and commit before the first retrieve.
3. Generate a manifest from `{{DEV_ALIAS}}` and retrieve (§9). Commit.
4. Fill in §1, §4 and §6 of this file and the TODOs in `CLAUDE.md` and the `deploy` skill.
5. Record which orgs deploy flows inactive and which record pages carry Prod-only components.
