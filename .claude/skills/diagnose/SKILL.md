---
name: diagnose
description: Establish the mechanism behind a Salesforce defect before proposing a fix. Use when a ticket reports a symptom, an error email arrives, something "stopped working", or behaviour is intermittent. Fires before `spec` and before `deploy`.
---

# Diagnosing a Salesforce defect

The job on this engagement is to **establish the actual mechanism**, not to produce a plausible one. A confident wrong diagnosis is worse than an open question: it gets built on, it consumes a deploy cycle, and it leaves the defect live behind a "fixed" label.

This skill is six gates. **Each gate has a pass criterion. Do not proceed past a gate you cannot pass** — say what you are missing instead.

| Gate | You may not proceed until… |
|---|---|
| 1 · Contain | every command is read-only and names its `--target-org` |
| 2 · Characterise | you can state scope, rate, first-seen and blast radius **as numbers** |
| 3 · Trace | you have reached an element that is *wrong*, not merely one that *failed* |
| 4 · Discriminate | a test has passed that would have **failed** if your hypothesis were wrong |
| 5 · Size | you have chosen the smallest change, not the tidiest end state |
| 6 · Prove | you have reproduced the failure **and** verified the fix by round-trip |

---

## Gate 1 — Contain before you look

⛔ **Diagnosis is read-only.** `sf data query`, `sf org list metadata`, `sf project retrieve` into
a scratch folder. Nothing that writes, until Gate 5 is approved.

- Pass an explicit, quoted `--target-org` on every command (see [[deploy]]).
- Retrieve into a **scratch project**, never over `force-app/`. Org metadata and repo metadata
  drift; the org is the source of truth for what is *running*, the repo is not.
- Read the instance URL back out of the output against the org you meant.

**Pass criterion:** no command in your history could have changed state.

---

## Gate 2 — Characterise the failure before explaining it

Resist the first explanation. Explanations are cheap; the shape of the failure is what constrains
them. Establish, with queries:

| Question | Where the answer usually lives |
|---|---|
| How many? | `AsyncApexJob`, `DeployRequest`, the affected object |
| What proportion? | failures ÷ total attempts — **an intermittent failure has a discriminator** |
| Since when? | oldest retained row — and **state the retention limit** |
| Who/what triggers it? | `CreatedById` on the failing artefact — guest user? integration? human? |
| What is the blast radius? | how many records/people are affected *now* |

⛔ **Never report a count without its window.** `AsyncApexJob`, debug logs and `DeployRequest` are
purged on rolling windows. "43 failures" means "43 in the retained window" — if failures appear at
the *oldest* retained row, the true start is unknown and earlier. Say so.

**Pass criterion:** you can state scope, rate, first-seen and retention limit as numbers.

---

## Gate 3 — Trace to the origin, not to the first failure

⛔ **The element that threw is rarely the element that is wrong.**

A failed lookup, a null reference, a missing field — these are *symptoms with an upstream
producer*. Walk backwards until you find something that is actually incorrect.

**The procedure.** For every empty or wrong value in the error:

1. Name the element that produced it.
2. Name every element that feeds *that* one.
3. Repeat until you reach a value that is wrong at its source.

⛔ **Do not substitute a known platform quirk for the remaining walk.** Recognising a familiar
pattern ("that's the Person Account timing thing", "that's a sharing issue", "that's a mixed-DML
error") is a hypothesis, not a finding. Platform behaviour is the **last** explanation to reach
for, after configuration and wiring are excluded — because config is far more often wrong, and is
cheap to check.

### Read the negative space

**What did *not* fail is evidence.** When an error names a list, the items *missing* from the list
localise the fault:

> `REQUIRED_FIELD_MISSING: [Username, LastName, Email, Alias]`
> — a fifth required field is *absent from this list*, so it was populated; whatever produced it
> still worked. The boundary between the two sets is where the fault is.

Apply this generally: the working branch, the passing record, the field that survived, the user
for whom it works. **Diff the failing case against the nearest working case** and the difference
is the cause or points directly at it.

### Re-read your own output

Evidence you have already gathered for another purpose frequently contains the answer. Before
forming a hypothesis, re-scan earlier tool output for anomalies you skipped because you were
looking for something else — duplicate references, counts that don't match, two connectors into
one element.

**Pass criterion:** you can point at a specific element/line and say *this is wrong*, not *this
returned nothing*.

---

## Gate 4 — Discriminate, don't confirm

⛔ **A check that cannot fail if you are wrong is not evidence.**

Before running a verification, write down: **what result would disprove this?** If no available
result would, the check is confirmatory — redesign it.

The classic failure is a second query that shares the first's blind spot (HANDOFF §7.7: a count
returned 35, and a second, identically-filtered query "corroborated" it; the truth was 99,130).

### The discriminating test for intermittent failures

If something fails some of the time, **something distinguishes the failures.** Find it in the
inputs before theorising about the platform:

```
What do the failures have in common that the successes do not?
```

Compare failure count against candidate populations until one matches. A population that matches
the failure count is a cause; a platform theory that merely *permits* the failure is not.

### Rank hypotheses by cheapness to falsify

Test the cheapest discriminator first, not the most interesting theory.

**Pass criterion:** a test has passed whose failure would have refuted your hypothesis — and you
can state what that failing result would have looked like.

---

## Gate 5 — Size the fix by blast radius, not by elegance

⛔ **The objective is the smallest change that fixes it — not the cleanest resulting design.**

For each candidate fix, state:

| | |
|---|---|
| Records/users on the **broken** path | the population you must fix |
| Records/users on the **working** path | the population you must not endanger |
| Does the fix modify the working path? | if yes, justify explicitly or reject |

A fix that routes a large working population through modified logic to repair a small broken one
is the wrong trade for a hotfix, however much tidier the result. **Refactors are a separate
ticket.**

⛔ **A fix derived from an unproven diagnosis will often appear to work.** If the defect is on a
minority path, testing the majority path proves nothing. Before proposing any fix, ask: *if my
diagnosis is wrong, would this fix visibly fail, or would it silently look fine?* If the latter,
return to Gate 4.

Also state what the fix does **not** address. Guards, logging and error handling discovered during
diagnosis are usually separable — bundling them makes the change unreviewable and the rollback
coarse.

**Pass criterion:** you have written down both populations and can defend leaving the working path
untouched.

---

## Gate 6 — Prove it

⛔ **A green deploy is not a fix, and a success message is not a test.** (See [[deploy]].)

1. **Reproduce the failure first, in the org you will fix.** A test that only runs after the fix
   proves it passes *alongside* the fix, not that it catches the defect. Generalised from
   HANDOFF §8 — this applies to diagnosis and deploys, not only to Apex tests.
2. **Capture the baseline** before changing anything: the failing record, the error, the counts.
   Once deployed, that evidence is unrecoverable.
3. **Verify by round-trip.** Retrieve the deployed metadata *back* from the org and diff it
   against the pre-change copy. Deploy output describes intent; the retrieve describes reality.
4. **Verify structurally**, not just textually — compare element counts by type. This catches
   accidental clobbering that a line diff can bury.
5. **Verify the outcome, not the interface.** If the defect's signature is "reports success while
   failing", a successful-looking screen proves nothing. Assert on the record that should exist.
6. **Keep a rollback.** Preserve the pre-change metadata somewhere durable — not a temp folder.

**Pass criterion:** you have a before, an after, and a check that would have caught the defect.

---

## Before promoting: environment parity

Metadata that works in one org can be inert in another. Before promoting, verify every **external
reference** resolves in the target, with the same identity and an active state:

| Pattern | Why it breaks |
|---|---|
| `$Label.*` holding an Id | label exists everywhere; its **value** is per-org |
| Custom Setting / Custom Metadata values | data, not metadata — may not travel |
| Lookups filtering on a **name** | Profile, RecordType, PermissionSet, Queue, User must exist *and be active* |
| Hardcoded 15/18-char Ids | never assume; verify in both orgs |
| Referenced flows/classes | may be a different **active version** per org |
| Site / community URLs, email addresses | environment-specific by definition |

Verify parity **at promotion time**, not from an earlier check — these orgs drift.

---

## Calibration vocabulary

⛔ Reserve **"confirmed"** and **"root cause"** for a mechanism that has passed Gate 4.

| Say | When |
|---|---|
| "consistent with" | evidence fits, rivals not excluded |
| "strongly indicated" | rivals are implausible but untested |
| **"confirmed"** | a discriminating test passed |
| "unknown" | say it plainly; it is a finding, not a gap to paper over |

State separately what is **proven** and what is **inferred**. When you are wrong, say so in one
line and move on — do not defend the earlier reading.

---

## Anti-patterns to check yourself against

| Anti-pattern | Counter |
|---|---|
| Matching to a familiar platform quirk early | Gate 3 — finish the upstream walk first |
| Running a check that merely fits | Gate 4 — state the falsifier before running it |
| Reporting certainty to sound useful | Calibration table — hedged and correct beats confident and wrong |
| Missing evidence already in your own output | Re-scan prior tool results before hypothesising |
| Proposing the elegant fix | Gate 5 — smallest change wins |
| Treating deploy success as completion | Gate 6 — round-trip and assert on outcome |
| Dropping a hypothesis because the user offered one | Test theirs the same way; agreement is not evidence either |

---

## Salesforce-specific heuristics

| Symptom | Look here first |
|---|---|
| Silent failure, user sees success | async boundary (`@future`, Queueable, Batch) — the caller returned before the work ran |
| "Stopped working", nothing in the error log | `AsyncApexJob.ExtendedStatus`. **Absence of logs is itself the signature** — a rollback erases logs written in the same transaction |
| Intermittent by proportion | a branch, a picklist value, an input characteristic — not the platform |
| Works for staff, fails for portal/public | Guest User context, sharing, `runInMode`, profile access |
| Counts far lower than expected | sharing-filtered query (HANDOFF §7.7); use a route that cannot be filtered |
| Fails only when automation writes it | validation rules evaluate `$Profile`/`$Permission` against the **starting** user (§7.8) |
| Fails on bulk, passes on one | `inputs[0]` only, or non-bulkified DML |
| Error names some fields but not others | read the negative space — Gate 3 |
| Feature deployed but invisible | page placement, permission-set assignment, flow activation (see [[deploy]]) |

⛔ **Much of the logic in these orgs lives in flows, not Apex.** Flows are XML: retrieve and `grep` them.
Count elements by type, list every connector into a shared element, and check which element a
downstream reference actually names. A duplicated element whose downstream reference was never
repointed is invisible in the flow canvas and obvious in the XML.

---

## Recording it

Write the mechanism into a spec (see [[spec]]) — what is **proven**, what is **inferred**, what is
**unknown**, and the discriminating test that settled it. State which orgs are affected and
whether the fix has been *reproduced* there or merely deployed.

If diagnosis surfaces a defect outside the ticket's scope, it gets its own ticket. Do not fix it
silently in the same change.
