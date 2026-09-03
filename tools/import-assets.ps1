<#  Resolves shaderpack / resourcepack zips in the Prism instance to Modrinth
    metadata and writes .pw.toml into <Pack>/<subfolder>/.
    List file format: one "<subfolder>/<exact zip filename>" per line, # for comments.
    Nothing is re-hosted - the metadata points at Modrinth's CDN.  #>
param(
    [Parameter(Mandatory)][string]$ListFile,
    [Parameter(Mandatory)][string]$Pack,
    [string]$Instance = "$env:APPDATA\PrismLauncher\instances\Mods(BG and Friends)"
)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$UA = @{ 'User-Agent' = 'packwiz-setup/1.0' }

# PS 5.1 Get-Content defaults to ANSI, which mangles the section sign in some pack names
$wanted = Get-Content -LiteralPath $ListFile -Encoding UTF8 | Where-Object { $_.Trim() -and $_ -notmatch '^\s*#' }
$ok = 0; $missing = @(); $notOnModrinth = @()

foreach ($line in $wanted) {
    $sub  = $line.Split('/')[0].Trim()
    $file = $line.Substring($line.IndexOf('/') + 1).Trim()
    $src  = Join-Path $Instance "minecraft\$sub\$file"
    if (-not (Test-Path -LiteralPath $src)) { $missing += $line; continue }

    $h = (Get-FileHash -Algorithm SHA512 -LiteralPath $src).Hash.ToLower()
    try   { $v = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version_file/$h`?algorithm=sha512" -Headers $UA }
    catch { $notOnModrinth += $line; continue }
    $pr = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/project/$($v.project_id)" -Headers $UA

    $f = $v.files | Where-Object { $_.hashes.sha512 -eq $h } | Select-Object -First 1
    if (-not $f) { $f = $v.files | Where-Object { $_.primary } | Select-Object -First 1 }

    $dir = Join-Path $Pack $sub
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $toml = @"
name = "$($pr.title -replace '"','\"')"
filename = "$($f.filename)"
side = "client"

[download]
url = "$($f.url)"
hash-format = "sha512"
hash = "$($f.hashes.sha512)"

[update]
[update.modrinth]
mod-id = "$($v.project_id)"
version = "$($v.id)"
"@
    [IO.File]::WriteAllText((Join-Path $dir "$($pr.slug).pw.toml"), ($toml -replace "`r`n","`n"))
    $ok++
    Start-Sleep -Milliseconds 250
}
Write-Host "  assets resolved: $ok" -ForegroundColor Green
if ($missing.Count)      { Write-Host "  NOT IN INSTANCE ($($missing.Count)):" -ForegroundColor Yellow; $missing | ForEach-Object { Write-Host "    $_" } }
if ($notOnModrinth.Count){ Write-Host "  NOT ON MODRINTH ($($notOnModrinth.Count)) - cannot ship:" -ForegroundColor Red; $notOnModrinth | ForEach-Object { Write-Host "    $_" } }
