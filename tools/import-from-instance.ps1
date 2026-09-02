<#
  Scans the Prism instance mods/ folder, identifies each jar on Modrinth by SHA512,
  and writes packwiz .pw.toml metadata. Jars that cannot be identified are reported.
  Read-only with respect to the Prism instance.
#>
param(
    [string]$Instance = "$env:APPDATA\PrismLauncher\instances\Mods(BG and Friends)",
    [string]$Pack     = "$PSScriptRoot\..",
    [switch]$ReportOnly
)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$UA = 'packwiz-setup/1.0 (github.com/packwiz)'

$modsDir = Join-Path $Instance 'minecraft\mods'
$packMods = Join-Path $Pack 'mods'
if (-not (Test-Path $packMods)) { New-Item -ItemType Directory -Path $packMods | Out-Null }

# .disabled jars are included too: Prism only renames the file, the contents are a normal jar.
# They ship ENABLED. To drop one later run remove-mod.bat (or delete its mods\<name>.pw.toml),
# then publish-pack-only.bat.
$jars = Get-ChildItem -LiteralPath $modsDir -File |
        Where-Object { $_.Name -match '\.jar(\.disabled)?$' } | Sort-Object Name

# honour the "keep in my instance but do not ship" list
$excludeFile = Join-Path $PSScriptRoot 'exclude-mods.txt'
$excludes = @()
if (Test-Path $excludeFile) {
    $excludes = @(Get-Content $excludeFile | Where-Object { $_.Trim() -and $_ -notmatch '^\s*#' } | ForEach-Object { $_.Trim() })
}
if ($excludes.Count) {
    $before = $jars.Count
    $jars = @($jars | Where-Object { $n = $_.Name; -not ($excludes | Where-Object { $n -like "*$_*" }) })
    Write-Host "Excluded $($before - $jars.Count) mod(s) via exclude-mods.txt" -ForegroundColor Yellow
}
Write-Host "Active jars found: $($jars.Count)" -ForegroundColor Cyan

# --- hash every jar -------------------------------------------------------
$byHash = @{}
foreach ($j in $jars) {
    $h = (Get-FileHash -Algorithm SHA512 -LiteralPath $j.FullName).Hash.ToLower()
    $byHash[$h] = $j
}

# --- bulk lookup on Modrinth (chunked) ------------------------------------
$versions = @{}
$allHashes = @($byHash.Keys)
for ($i = 0; $i -lt $allHashes.Count; $i += 100) {
    $chunk = $allHashes[$i..([Math]::Min($i+99, $allHashes.Count-1))]
    $body  = @{ hashes = $chunk; algorithm = 'sha512' } | ConvertTo-Json -Compress
    $resp  = Invoke-RestMethod -Method Post -Uri 'https://api.modrinth.com/v2/version_files' `
             -ContentType 'application/json' -Body $body -Headers @{ 'User-Agent' = $UA }
    foreach ($p in $resp.PSObject.Properties) { $versions[$p.Name.ToLower()] = $p.Value }
    Start-Sleep -Milliseconds 400
}
Write-Host "Matched on Modrinth: $($versions.Count) / $($jars.Count)" -ForegroundColor Green

# --- fetch project metadata for slug + side -------------------------------
$projIds = @($versions.Values | ForEach-Object { $_.project_id } | Sort-Object -Unique)
$projects = @{}
for ($i = 0; $i -lt $projIds.Count; $i += 100) {
    $chunk = $projIds[$i..([Math]::Min($i+99, $projIds.Count-1))]
    $ids   = ($chunk | ConvertTo-Json -Compress)
    if ($chunk.Count -eq 1) { $ids = "[$($chunk | ConvertTo-Json -Compress)]" }
    $uri   = 'https://api.modrinth.com/v2/projects?ids=' + [uri]::EscapeDataString($ids)
    $resp  = Invoke-RestMethod -Uri $uri -Headers @{ 'User-Agent' = $UA }
    foreach ($pr in $resp) { $projects[$pr.id] = $pr }
    Start-Sleep -Milliseconds 400
}

# --- emit .pw.toml --------------------------------------------------------
$written = @(); $unmatched = @()
foreach ($h in $byHash.Keys) {
    $jar = $byHash[$h]
    if (-not $versions.ContainsKey($h)) { $unmatched += $jar.Name; continue }
    $v   = $versions[$h]
    $pr  = $projects[$v.project_id]
    $slug = if ($pr) { $pr.slug } else { $v.project_id }

    # the file entry whose hash matches ours (a version can ship several files)
    $file = $v.files | Where-Object { $_.hashes.sha512 -eq $h } | Select-Object -First 1
    if (-not $file) { $file = $v.files | Where-Object { $_.primary } | Select-Object -First 1 }

    $side = 'both'
    if ($pr) {
        if ($pr.server_side -eq 'unsupported') { $side = 'client' }
        elseif ($pr.client_side -eq 'unsupported') { $side = 'server' }
    }
    $name = if ($pr) { $pr.title } else { $jar.BaseName }

    $toml = @"
name = "$($name -replace '"','\"')"
filename = "$($file.filename)"
side = "$side"

[download]
url = "$($file.url)"
hash-format = "sha512"
hash = "$($file.hashes.sha512)"

[update]
[update.modrinth]
mod-id = "$($v.project_id)"
version = "$($v.id)"
"@
    if (-not $ReportOnly) {
        [IO.File]::WriteAllText((Join-Path $packMods "$slug.pw.toml"), ($toml -replace "`r`n","`n"))
    }
    $written += "$slug  <-  $($jar.Name)"
}

Write-Host ""
Write-Host "=== WROTE $($written.Count) METADATA FILES ===" -ForegroundColor Green
Write-Host ""
Write-Host "=== UNMATCHED ($($unmatched.Count)) - not found on Modrinth by hash ===" -ForegroundColor Yellow
$unmatched | Sort-Object | ForEach-Object { Write-Host "  $_" }
$unmatched | Sort-Object | Set-Content -Encoding utf8 (Join-Path $Pack '_backups\unmatched-mods.txt')
