<#  Builds the zip friends import.

    Everything comes from files this repo owns - nothing is read from a live
    Prism instance. That instance was deleted once mid-project and silently
    produced 1 KB zips containing only instance.cfg, so the build now depends
    on nothing external and REFUSES to produce a zip that is missing a file.

    instance.cfg  <- friend-instance.cfg.template  (pre-launch command injected)
    mmc-pack.json <- mmc-pack.json.template        (versions read from pack.toml)
    bootstrap jar <- tools/dist/                   (committed to the repo)

    Entry names use forward slashes; Compress-Archive writes backslashes, which
    is outside the ZIP spec and breaks some extractors.
#>
param(
    [ValidateSet('base','plus')][string]$Variant = 'base',
    [string]$Out,
    [string]$PackUrl
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$repo = Resolve-Path "$PSScriptRoot\.."
$site = 'https://brandong0123.github.io/minecraft-modpack-updates'
if ($Variant -eq 'plus') {
    if (-not $Out)     { $Out     = "$repo\Tylers Mods Plus.zip" }
    if (-not $PackUrl) { $PackUrl = "$site/plus/pack.toml" }
    $instName = 'Tylers Mods Plus'
    $packToml = "$repo\plus\pack.toml"
} else {
    if (-not $Out)     { $Out     = "$repo\Tylers Mods.zip" }
    if (-not $PackUrl) { $PackUrl = "$site/pack.toml" }
    $instName = 'Tylers Mods'
    $packToml = "$repo\pack.toml"
}

# ---- instance.cfg from template -----------------------------------------
# Prism's canonical form: inner quotes escaped as \" with no outer wrapping.
$q = [char]92 + '"'
$pre = "$q`$INST_JAVA$q -jar $q`$INST_MC_DIR/packwiz-installer-bootstrap.jar$q" +
       " --bootstrap-main-jar $q`$INST_MC_DIR/packwiz-installer.jar$q" +
       " --pack-folder $q`$INST_MC_DIR$q --multimc-folder $q`$INST_DIR$q" +
       " --title $q$instName$q -s client $PackUrl"
$cfg = ([IO.File]::ReadAllText("$PSScriptRoot\friend-instance.cfg.template")).
         Replace('__PRELAUNCH__', $pre).Replace('name=Tylers Mods', "name=$instName")
$tmpCfg = Join-Path $env:TEMP 'fz-instance.cfg'
[IO.File]::WriteAllText($tmpCfg, $cfg)

# ---- mmc-pack.json, versions taken from the pack itself -----------------
$pt = [IO.File]::ReadAllText($packToml)
if ($pt -notmatch '(?m)^minecraft = "(.+)"$') { throw "no minecraft version in $packToml" }
$mc = $Matches[1]
if ($pt -notmatch '(?m)^fabric = "(.+)"$')    { throw "no fabric version in $packToml" }
$fl = $Matches[1]
$mmc = ([IO.File]::ReadAllText("$PSScriptRoot\mmc-pack.json.template")).
         Replace('__MC__', $mc).Replace('__FABRIC__', $fl)
$tmpMmc = Join-Path $env:TEMP 'fz-mmc-pack.json'
[IO.File]::WriteAllText($tmpMmc, $mmc)

# ---- assemble ------------------------------------------------------------
$include = @(
    @{ src = $tmpCfg;                                          entry = "$instName/instance.cfg" }
    @{ src = $tmpMmc;                                          entry = "$instName/mmc-pack.json" }
    @{ src = "$PSScriptRoot\dist\packwiz-installer-bootstrap.jar"; entry = "$instName/minecraft/packwiz-installer-bootstrap.jar" }
)
$missing = @($include | Where-Object { -not (Test-Path -LiteralPath $_.src) })
if ($missing.Count) {
    Write-Host "*** ZIP NOT BUILT - source file missing ***" -ForegroundColor Red
    $missing | ForEach-Object { Write-Host "  $($_.entry)  <- $($_.src)" -ForegroundColor Red }
    exit 1
}

if (Test-Path $Out) { Remove-Item -LiteralPath $Out -Force }
$zip = [IO.Compression.ZipFile]::Open($Out, [IO.Compression.ZipArchiveMode]::Create)
try {
    # Explorer renders a zip with no directory entries as an empty folder
    foreach ($d in @("$instName/", "$instName/minecraft/")) { $zip.CreateEntry($d) | Out-Null }
    foreach ($i in $include) {
        [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $i.src, $i.entry) | Out-Null
        Write-Host "  + $($i.entry)"
    }
} finally { $zip.Dispose() }
Remove-Item $tmpCfg,$tmpMmc -Force -ErrorAction SilentlyContinue

# ---- verify before anyone can download it -------------------------------
$check = [IO.Compression.ZipFile]::OpenRead($Out)
$names = @($check.Entries | ForEach-Object { $_.FullName })
$bad   = @($check.Entries | Where-Object { $_.FullName.Contains([char]92) })
$e     = $check.Entries | Where-Object { $_.FullName -eq "$instName/instance.cfg" }
$sr    = New-Object IO.StreamReader($e.Open()); $shipped = $sr.ReadToEnd(); $sr.Close()
$jar   = $check.Entries | Where-Object { $_.FullName -like '*bootstrap.jar' }
$check.Dispose()

$fail = @()
foreach ($req in @("$instName/instance.cfg","$instName/mmc-pack.json","$instName/minecraft/packwiz-installer-bootstrap.jar")) {
    if ($names -notcontains $req) { $fail += "missing required entry: $req" }
}
if ($jar -and $jar.Length -lt 50000)              { $fail += "bootstrap jar looks truncated ($($jar.Length) bytes)" }
if ($bad.Count)                                   { $fail += "backslash entry names" }
if ($shipped -notmatch [regex]::Escape($PackUrl)) { $fail += "pack URL missing or wrong" }
if ($shipped -match 'example\.invalid')           { $fail += "placeholder URL present" }
if ($shipped -match 'probe')                      { $fail += "debug probe command present" }
if ($shipped -notmatch 'OverrideCommands=true')   { $fail += "OverrideCommands not enabled" }
if ($mmc -notmatch [regex]::Escape($mc))          { $fail += "mmc-pack.json missing MC version" }
foreach ($n in $names) {
    if ($n -match 'saves/|screenshots/|shaderpacks/|resourcepacks/|xaero|options\.txt') { $fail += "personal file: $n" }
    if ($n -match '\.jar$' -and $n -notmatch 'bootstrap\.jar$')                          { $fail += "mod jar: $n" }
}
if ($fail.Count) {
    Write-Host ""
    Write-Host "*** ZIP REJECTED ***" -ForegroundColor Red
    $fail | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    Remove-Item -LiteralPath $Out -Force
    exit 1
}
Write-Host ""
Write-Host "Built and verified: $([math]::Round((Get-Item $Out).Length/1KB)) KB, $($names.Count) entries  [MC $mc / Fabric $fl]" -ForegroundColor Green
Write-Host "  pack URL: $PackUrl" -ForegroundColor DarkGray
