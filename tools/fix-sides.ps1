<#  Corrects mod sides for transitive client-only dependencies.

    A mod's own fabric.mod.json "environment" is not sufficient. Voxy declares
    "*" but hard-depends on Sodium, which is client-only - putting it on a
    dedicated server makes Fabric refuse to start:

      Mod 'Voxy' requires version ... of sodium, which is missing!

    So: seed the client-only set from declared environment, then repeatedly add
    any mod that hard-depends on something already in the set, until it settles.
    Those get side = "client" regardless of what they declare.
#>
param(
    [string]$Pack     = "$PSScriptRoot\..",
    [string]$Instance = "$env:APPDATA\PrismLauncher\instances\Mods(BG and Friends)"
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

$modsDir = Join-Path $Instance 'minecraft\mods'
$info = @{}
foreach ($j in Get-ChildItem -LiteralPath $modsDir -File | Where-Object { $_.Name -match '\.jar(\.disabled)?$' }) {
    try {
        $z = [IO.Compression.ZipFile]::OpenRead($j.FullName)
        $e = $z.Entries | Where-Object { $_.FullName -eq 'fabric.mod.json' } | Select-Object -First 1
        if ($e) {
            $sr = New-Object IO.StreamReader($e.Open()); $t = $sr.ReadToEnd(); $sr.Close()
            $id  = if ($t -match '"id"\s*:\s*"([^"]+)"') { $Matches[1] } else { $j.BaseName }
            $env = if ($t -match '"environment"\s*:\s*"([^"]+)"') { $Matches[1] } else { '*' }
            $dep = @()
            if ($t -match '(?s)"depends"\s*:\s*\{(.*?)\}') {
                $dep = [regex]::Matches($Matches[1], '"([^"]+)"\s*:') | ForEach-Object { $_.Groups[1].Value }
            }
            $info[$id] = [pscustomobject]@{ Id=$id; Env=$env; Depends=$dep; FileName=$j.Name -replace '\.disabled$','' }
        }
        $z.Dispose()
    } catch { }
}

$clientOnly = [Collections.Generic.HashSet[string]]::new()
foreach ($m in $info.Values) { if ($m.Env -eq 'client') { [void]$clientOnly.Add($m.Id) } }
$seed = $clientOnly.Count

$promoted = @()
$changed = $true
while ($changed) {
    $changed = $false
    foreach ($m in $info.Values) {
        if ($clientOnly.Contains($m.Id)) { continue }
        foreach ($d in $m.Depends) {
            if ($clientOnly.Contains($d)) {
                [void]$clientOnly.Add($m.Id)
                $promoted += "$($m.Id) (depends on $d)"
                $changed = $true; break
            }
        }
    }
}

# map declared-client filenames onto the pack metadata and rewrite side
$byFile = @{}
foreach ($m in $info.Values) { if ($clientOnly.Contains($m.Id)) { $byFile[$m.FileName] = $true } }

$fixed = 0
foreach ($f in Get-ChildItem (Join-Path $Pack 'mods') -Filter *.pw.toml -File) {
    $txt = [IO.File]::ReadAllText($f.FullName)
    if ($txt -notmatch '(?m)^filename = "(.+)"$') { continue }
    $fn = $Matches[1]
    if (-not $byFile.ContainsKey($fn)) { continue }
    if ($txt -match '(?m)^side = "client"$') { continue }
    [IO.File]::WriteAllText($f.FullName, ($txt -replace '(?m)^side = "(both|server)"$','side = "client"'))
    $fixed++
}

# Manual overrides win over anything derived above - derivation cannot know
# that a mod is capable of running somewhere but unwanted there.
$ovFile = Join-Path $PSScriptRoot 'side-overrides.txt'
$applied = @()
if (Test-Path $ovFile) {
    foreach ($line in (Get-Content $ovFile | Where-Object { $_.Trim() -and $_ -notmatch '^\s*#' })) {
        $parts = $line -split '=',2
        if ($parts.Count -ne 2) { continue }
        $name = $parts[0].Trim(); $want = $parts[1].Trim()
        if ($want -notin @('client','server','both')) { Write-Host "  bad override: $line" -ForegroundColor Red; continue }
        $mf = Join-Path $Pack "mods\$name.pw.toml"
        if (-not (Test-Path -LiteralPath $mf)) { Write-Host "  override target not in pack: $name" -ForegroundColor DarkYellow; continue }
        $txt = [IO.File]::ReadAllText($mf)
        if ($txt -match "(?m)^side = ""$want""$") { continue }
        [IO.File]::WriteAllText($mf, ($txt -replace '(?m)^side = "(client|server|both)"$', "side = ""$want"""))
        $applied += "$name -> $want"
    }
}
if ($applied.Count) {
    Write-Host "  manual overrides applied:" -ForegroundColor Cyan
    $applied | ForEach-Object { Write-Host "    $_" }
}

Write-Host "  declared client-only: $seed" -ForegroundColor DarkGray
if ($promoted.Count) {
    Write-Host "  promoted to client-only (transitive):" -ForegroundColor Yellow
    $promoted | Sort-Object -Unique | ForEach-Object { Write-Host "    $_" }
} else { Write-Host "  no transitive promotions" -ForegroundColor DarkGray }
Write-Host "  metadata files corrected: $fixed" -ForegroundColor Green
