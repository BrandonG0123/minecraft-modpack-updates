<#  Reports differences between the Prism instance and the published packwiz pack.
    Read-only. Changes nothing.  #>
param(
    [string]$Instance = "$env:APPDATA\PrismLauncher\instances\Mods(BG and Friends)",
    [string]$Pack     = "$PSScriptRoot\.."
)
$ErrorActionPreference = 'Stop'
$instMods = Join-Path $Instance 'minecraft\mods'
$packMods = Join-Path $Pack 'mods'

# --- mods -----------------------------------------------------------------
# .disabled jars count too - they are in the pack and ship enabled
$instJars = @(Get-ChildItem -LiteralPath $instMods -File |
              Where-Object { $_.Name -match '\.jar(\.disabled)?$' } |
              ForEach-Object { $_.Name -replace '\.disabled$','' })
$packJars = @()
$packMap  = @{}
foreach ($f in Get-ChildItem -LiteralPath $packMods -Filter *.pw.toml -File) {
    $fn = (Select-String -LiteralPath $f.FullName -Pattern '^filename = "(.+)"$').Matches[0].Groups[1].Value
    $packJars += $fn
    $packMap[$fn] = $f.BaseName -replace '\.pw$',''
}

$onlyInstance = @($instJars | Where-Object { $packJars -notcontains $_ })
$onlyPack     = @($packJars | Where-Object { $instJars -notcontains $_ })

Write-Host ""
Write-Host "======== MOD DIFF ========" -ForegroundColor Cyan
Write-Host "instance: $($instJars.Count) active jars   pack: $($packJars.Count) managed mods"
Write-Host ""
Write-Host "IN YOUR INSTANCE, NOT IN THE PACK  ($($onlyInstance.Count))" -ForegroundColor Yellow
Write-Host "  -> friends will NOT get these. Run sync-from-instance.bat to add them."
if ($onlyInstance.Count -eq 0) { Write-Host "  (none)" -ForegroundColor DarkGray }
$onlyInstance | Sort-Object | ForEach-Object { Write-Host "  + $_" -ForegroundColor Green }
Write-Host ""
Write-Host "IN THE PACK, NOT IN YOUR INSTANCE  ($($onlyPack.Count))" -ForegroundColor Yellow
Write-Host "  -> friends still get these. Usually means you updated or deleted the jar locally."
if ($onlyPack.Count -eq 0) { Write-Host "  (none)" -ForegroundColor DarkGray }
$onlyPack | Sort-Object | ForEach-Object { Write-Host "  - $_   [$($packMap[$_])]" -ForegroundColor Red }

# --- managed configs ------------------------------------------------------
Write-Host ""
Write-Host "======== MANAGED CONFIG DIFF ========" -ForegroundColor Cyan
$listFile = Join-Path $PSScriptRoot 'managed-configs.txt'
$drift = 0
foreach ($rel in (Get-Content $listFile | Where-Object { $_ -and $_ -notmatch '^\s*#' })) {
    # '!' marks a pack-owned file - it is not expected to match the instance
    if ($rel.StartsWith("!")) { continue }
    $a = Join-Path $Instance "minecraft\$rel"
    $b = Join-Path $Pack $rel
    if (-not (Test-Path -LiteralPath $a)) { Write-Host "  ! missing in instance: $rel" -ForegroundColor Red; $drift++; continue }
    if (-not (Test-Path -LiteralPath $b)) { Write-Host "  ! missing in pack:     $rel" -ForegroundColor Red; $drift++; continue }
    $ha = (Get-FileHash -Algorithm SHA256 -LiteralPath $a).Hash
    $hb = (Get-FileHash -Algorithm SHA256 -LiteralPath $b).Hash
    if ($ha -ne $hb) { Write-Host "  ~ changed locally:     $rel" -ForegroundColor Yellow; $drift++ }
}
if ($drift -eq 0) { Write-Host "  all managed configs in sync" -ForegroundColor DarkGray }

Write-Host ""
if ($onlyInstance.Count -or $onlyPack.Count -or $drift) {
    Write-Host "ACTION: run  sync-from-instance.bat  then  publish.bat" -ForegroundColor Cyan
} else {
    Write-Host "Pack matches your instance. Nothing to publish." -ForegroundColor Green
}
Write-Host ""
