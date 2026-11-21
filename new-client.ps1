<#
.SYNOPSIS
  Create a new client Salesforce project from this template.

.EXAMPLE
  .\new-client.ps1 -ClientName "Acme Foundation" -ClientShort ACME

  Creates ..\ACME with aliases ACMEDev / ACMEUAT / ACMEProd and ticket key ACME-###.

.EXAMPLE
  .\new-client.ps1 -ClientName "Acme Foundation" -ClientShort ACME -TicketKey AF `
    -Destination "C:\Users\me\OneDrive\Desktop\Acme"
#>
param(
    [Parameter(Mandatory)] [string] $ClientName,
    [Parameter(Mandatory)] [string] $ClientShort,
    [string] $TicketKey,
    [string] $DevAlias,
    [string] $UatAlias,
    [string] $ProdAlias,
    [string] $Destination,
    [switch] $SkipInstall
)

$ErrorActionPreference = 'Stop'
$template = $PSScriptRoot

if ($ClientShort -notmatch '^[A-Za-z][A-Za-z0-9]*$') {
    throw "ClientShort must be letters/digits only (it becomes the alias prefix): '$ClientShort'"
}
if (-not $TicketKey)   { $TicketKey   = $ClientShort.ToUpper() }
if (-not $DevAlias)    { $DevAlias    = "${ClientShort}Dev" }
if (-not $UatAlias)    { $UatAlias    = "${ClientShort}UAT" }
if (-not $ProdAlias)   { $ProdAlias   = "${ClientShort}Prod" }
if (-not $Destination) { $Destination = Join-Path (Split-Path $template -Parent) $ClientShort }

foreach ($a in $DevAlias, $UatAlias, $ProdAlias) {
    if ($a -match '\s') { throw "Alias '$a' contains a space. Pick one without — see HANDOFF §7.1." }
}
if (Test-Path $Destination) { throw "Destination already exists: $Destination" }

$Destination = [IO.Path]::GetFullPath($Destination)
if ($Destination.StartsWith([IO.Path]::GetFullPath($template), 'OrdinalIgnoreCase')) {
    throw "Destination must not be inside the template folder."
}

# Claude Code loads CLAUDE.md from every parent folder — refuse to nest inside another project.
$parent = Split-Path $Destination -Parent
while ($parent) {
    if (Test-Path (Join-Path $parent 'CLAUDE.md')) {
        throw "A parent folder already has a CLAUDE.md ($parent). Its instructions would load into this project. Choose another location."
    }
    $parent = Split-Path $parent -Parent
}

# The CLI aliases are machine-wide: warn if these names already point at an org.
$existing = @()
try {
    $orgs = (sf org list --json 2>$null | ConvertFrom-Json).result
    $all = @($orgs.nonScratchOrgs) + @($orgs.sandboxes) + @($orgs.other) + @($orgs.devHubs)
    $existing = $all | Where-Object { $_.alias -in @($DevAlias, $UatAlias, $ProdAlias) } |
        ForEach-Object { "$($_.alias) -> $($_.instanceUrl)" } | Sort-Object -Unique
} catch { }
if ($existing) {
    Write-Warning "These aliases already exist on this machine and will be reused:`n  $($existing -join "`n  ")"
}

Write-Host "Creating $Destination"
New-Item -ItemType Directory -Path $Destination | Out-Null
Get-ChildItem -LiteralPath $template -Force |
    Where-Object { $_.Name -notin @('node_modules', '.git', 'new-client.ps1', 'README.md') } |
    Copy-Item -Destination $Destination -Recurse -Force

$tokens = [ordered]@{
    '{{CLIENT_NAME}}'  = $ClientName
    '{{CLIENT_SHORT}}' = $ClientShort
    '{{TICKET_KEY}}'   = $TicketKey
    '{{DEV_ALIAS}}'    = $DevAlias
    '{{UAT_ALIAS}}'    = $UatAlias
    '{{PROD_ALIAS}}'   = $ProdAlias
}
$utf8 = New-Object System.Text.UTF8Encoding($false)
$files = Get-ChildItem -LiteralPath $Destination -Recurse -File -Force -Include *.md, *.json |
    Where-Object { $_.Name -ne 'package-lock.json' }
foreach ($f in $files) {
    $text = [IO.File]::ReadAllText($f.FullName)
    $new = $text
    foreach ($k in $tokens.Keys) { $new = $new.Replace($k, $tokens[$k]) }
    if ($new -ne $text) { [IO.File]::WriteAllText($f.FullName, $new, $utf8) }
}

[IO.File]::WriteAllText((Join-Path $Destination 'README.md'), @"
# $ClientShort — $ClientName Salesforce

Start with [HANDOFF.md](HANDOFF.md). Orgs: ``$DevAlias`` → ``$UatAlias`` → ``$ProdAlias``.
"@, $utf8)

$left = Get-ChildItem -LiteralPath $Destination -Recurse -File -Force |
    Select-String -Pattern '\{\{[A-Z_]+\}\}' -List | ForEach-Object { $_.Path }
if ($left) { Write-Warning "Unreplaced tokens remain in:`n  $($left -join "`n  ")" }

Push-Location $Destination
try {
    git init --quiet
    if (-not $SkipInstall) { npm install --no-fund --no-audit }
} finally { Pop-Location }

$todo = (Get-ChildItem -LiteralPath $Destination -Recurse -File -Include *.md -Force |
    Where-Object { $_.FullName -notmatch '\\node_modules\\' } |
    Select-String -Pattern 'TODO' | Measure-Object).Count

Write-Host ""
Write-Host "Done: $Destination" -ForegroundColor Green
Write-Host "  Aliases: $DevAlias -> $UatAlias -> $ProdAlias   Tickets: $TicketKey-###"
Write-Host "  Default org (.sf/config.json): $DevAlias"
Write-Host "  $todo TODO markers to fill in (CLAUDE.md, HANDOFF.md, deploy skill)."
Write-Host ""
Write-Host "Next, log in (fill in the client's My Domain):"
Write-Host "  sf org login web --alias $DevAlias  --instance-url https://<mydomain>--dev.sandbox.my.salesforce.com"
Write-Host "  sf org login web --alias $UatAlias  --instance-url https://<mydomain>--uat.sandbox.my.salesforce.com"
Write-Host "  sf org login web --alias $ProdAlias --instance-url https://login.salesforce.com"
Write-Host "Then commit, and retrieve (HANDOFF.md §9)."
