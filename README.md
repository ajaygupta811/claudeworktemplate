# Salesforce client project template (Accelerize360)

A client-neutral starting point for a ticket-driven Salesforce engagement: SFDX project
scaffolding, lint/format tooling, and the Claude Code setup (`CLAUDE.md`, `HANDOFF.md`, and the
`deploy`, `spec`, `diagnose` and `platform-soql-query` skills).

**Don't work in this folder.** Generate a project from it:

```powershell
cd "$HOME\OneDrive\Desktop\sf-client-template"
.\new-client.ps1 -ClientName "Acme Foundation" -ClientShort ACME
```

This creates `..\ACME\` next to the template. It will:

- fill in the `{{TOKENS}}` — client name, alias prefix, Jira key, and the three org aliases
  (`ACMEDev` / `ACMEUAT` / `ACMEProd` by default; override with `-DevAlias`, `-UatAlias`,
  `-ProdAlias`, `-TicketKey`, `-Destination`)
- point the project's default org (`.sf/config.json`) at the **dev sandbox**, never production
- `git init` and `npm install` (use `-SkipInstall` to skip the install)
- refuse a destination that sits inside another folder with a `CLAUDE.md`, because Claude Code
  would load that project's instructions as well

After it runs, log in to the orgs (the script prints the commands), commit, retrieve, and fill in
the `TODO` markers in `CLAUDE.md`, `HANDOFF.md` and `.claude/skills/deploy/SKILL.md`.

## Maintaining the template

When a client project turns up a trap that is Salesforce or CLI behaviour, not a fact about that
client, add it here as well: in `HANDOFF.md` §7 and/or the `deploy` skill. Nothing
client-specific belongs in this folder. Before committing a change, search it:

```powershell
Get-ChildItem -Recurse -File | Select-String -Pattern '<client names>' -List
```
