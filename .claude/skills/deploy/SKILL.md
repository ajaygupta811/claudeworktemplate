---
name: deploy
description: Deploy or retrieve {{CLIENT_SHORT}} metadata with the correct org alias. Use for any `sf project deploy`, `sf project retrieve`, or Apex test run in this project.
---

# Deploying {{CLIENT_SHORT}}

## ⛔ Always pass `--target-org`

`sf org list` on this machine holds aliases for **every client you have logged in to**. A
command pointed at the wrong alias does not fail — it deploys into another company's org, and
nothing in the CLI output names the company, only the instance URL.

The project default (`.sf/config.json`) is `{{DEV_ALIAS}}`, so an omitted flag lands in the dev
sandbox rather than production. Pass the flag anyway; the default is a safety net, not a
convention.

## The orgs

| you want | alias | instance |
|---|---|---|
| {{CLIENT_SHORT}} dev sandbox | `{{DEV_ALIAS}}` | <!-- TODO: mydomain--dev.sandbox.my.salesforce.com --> |
| {{CLIENT_SHORT}} UAT sandbox | `{{UAT_ALIAS}}` | <!-- TODO --> |
| {{CLIENT_SHORT}} production | `{{PROD_ALIAS}}` | <!-- TODO --> |

Only the `{{CLIENT_SHORT}}` prefix is this client. `UAT`, `Dev4`, `DevOrg` and other generic
aliases belong to other engagements. After any deploy or retrieve, **read the instance URL in the
output back against the table above.**

Keep aliases free of spaces. If one does contain a space, quote it on every command — unquoted,
`sf` reads the first word as the alias and the rest as a stray argument.

## Promotion order

`{{DEV_ALIAS}}` → `{{UAT_ALIAS}}` → `{{PROD_ALIAS}}`. Never deploy to UAT or Production without
the change having landed and passed its tests in the environment before it.

## Validate before you deploy

Dry-run first — `--dry-run` checks deployability without writing:

```powershell
sf project deploy start --dry-run --target-org {{DEV_ALIAS}} `
  --source-dir force-app/main/default/classes/MyService.cls
```

## Production deploys run specified tests

Production uses `RunSpecifiedTests`, naming the test classes covering the change — not
`RunLocalTests`, which runs every test class in the org and takes far longer:

```powershell
sf project deploy start --target-org {{PROD_ALIAS}} `
  --test-level RunSpecifiedTests --tests MyServiceTest `
  --source-dir force-app/main/default/classes
```

Sandboxes may deploy without a test level, but run the relevant test class afterward:

```powershell
sf apex run test --target-org {{DEV_ALIAS}} --tests MyServiceTest `
  --result-format human --wait 10
```

## ⛔ A green deploy does not mean the feature is live

Deploys routinely land **inert**: a quick action, LWC or flow can deploy successfully and still be
invisible to every user, because page placement, permission-set assignment and flow activation
are manual admin steps done per environment. Before reporting a feature as delivered, check the
spec's "Manual step to finish the rollout" section and say plainly which manual steps are still
outstanding in which org.

Deployment success is a statement about metadata, not about whether anyone can use the thing.

## After deploying, update the ledger

Every spec in `docs/` carries a **Deployment status** section with one line per org. Update it —
which components went, which test class passed and at what coverage, and what remains. See
[[spec]] for the format.

## ⛔ On Windows, `sf` reports failure on a deploy that succeeded

A deploy that ends with a non-zero exit and

```
Error (MetadataTransferError): Metadata API request failed: Missing message
metadata.transfer:Finalizing for locale en_US
```

**has already committed.** It is a locale/i18n bug in the CLI's final progress render, not a
deploy failure. Scrape the `Deploy ID:` line and confirm with
`sf project deploy report --job-id <id> --json`. Never re-deploy on the strength of that message.

Two siblings from the same family: aggregate SOQL returns **blank columns** under
`--result-format csv` (use `--json` and read `result.records`), and `sf` **breaks in the Bash
tool whenever an argument contains a space** — it dies with `'C:\Program' is not recognized`.
Bare-word commands work, which makes it look intermittent. **Run every `sf` command through
PowerShell.**

## ⛔ Production refuses any class a scheduled job references

```
This schedulable class has jobs pending or in progress - CronTrigger IDs (08e...)
```

0/N components, before any test runs. Budget **three deploys, not one**:

```powershell
sf project retrieve start --target-org {{PROD_ALIAS}} --metadata "Settings:Deployment"
# doesSkipAsyncApexValidation false -> true, deploy it
# deploy the classes
# set it back true -> false, deploy it, then RE-RETRIEVE to verify the stored value
```

- The metadata member is **`Deployment`, not `Deploy`** — `Settings:Deploy` fails with *"The
  object 'Deploy' of type Settings metadata does not exist"*, which reads like a permissions
  problem and is not.
- `--output-dir` onto a bare temp folder fails with `ENOENT ... main\default`. Retrieve into a
  scratch folder that already holds an `sfdx-project.json` and `force-app/main/default/`.
- **Put the setting back.** Left flipped, it removes that protection org-wide for every future
  deploy by anyone. A `Succeeded 1/1` is not proof of the stored value — re-retrieve it.
- **Never delete and re-create the scheduled job instead.** The cron is read in the *running
  user's* timezone, so re-scheduling under a different user silently moves the fire time.
  Scheduled Apex resolves the class at fire time, so a deployed change is picked up on the next
  run with no rescheduling at all.

## ⛔ The orgs drift — retrieve the target's own copy before editing

Flows, flexipages and layouts differ per org: different active flow versions, actions and
components added in Production by admins that Dev and UAT never had. Deploying a Dev copy of a
flexipage or flow clobbers them. Retrieve the target org's version into a scratch folder, diff,
and edit that.

Some orgs deploy flows **inactive** (a Production org setting that sandboxes often do not share).
If a flow lands as Draft, activate it with a `flowDefinitions/` deploy setting
`activeVersionNumber`.

<!-- TODO: record this client's confirmed drift here as you find it (which org deploys flows
inactive, which pages carry Prod-only components). -->

## Conventions

- Test classes are `<ClassName>Test.cls`.
- API version <!-- TODO: from sfdx-project.json -->, single package dir `force-app`.
- `npm run prettier` and `npm run lint` before committing; husky + lint-staged run on commit.
