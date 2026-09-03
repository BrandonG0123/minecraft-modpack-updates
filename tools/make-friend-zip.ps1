<#  Builds the zip you give your friends.

    instance.cfg is generated from friend-instance.cfg.template, NOT copied from the
    live Prism instance. Prism rewrites instance.cfg from its own memory whenever it
    reloads, which once silently shipped a debug command pointing at example.invalid.
    Generating it here keeps the deliverable independent of whatever Prism is doing.

    Entry names use forward slashes: Compress-Archive writes backslashes, which is
    outside the ZIP spec and breaks some extractors.
#>
param(
    [string]$Instance = "$env:APPDATA\PrismLauncher\instances\Tylers Mods",
    [string]$Out      = "$PSScriptRoot\..\Tylers Mods.zip",
    [string]$PackUrl  = "https://brandong0123.github.io/minecraft-modpack-updates/pack.toml"
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$name = 'Tylers Mods'

# --- build instance.cfg from the template --------------------------------
# Prism's canonical form: inner quotes escaped as \" with no outer wrapping.
$q = [char]92 + '"'
$pre = "$q`$INST_JAVA$q -jar $q`$INST_MC_DIR/packwiz-installer-bootstrap.jar$q" +
       " --bootstrap-main-jar $q`$INST_MC_DIR/packwiz-installer.jar$q" +
       " --pack-folder $q`$INST_MC_DIR$q --multimc-folder $q`$INST_DIR$q" +
       " --title ${q}Tylers Mods$q -s client $PackUrl"
$cfg = ([IO.File]::ReadAllText("$PSScriptRoot\friend-instance.cfg.template")).Replace('__PRELAUNCH__', $pre)

$tmp = Join-Path $env:TEMP 'friend-instance.cfg'
[IO.File]::WriteAllText($tmp, $cfg)

# --- assemble -------------------------------------------------------------
$include = @(
    @{ src = $tmp;                                                  entry = "$name/instance.cfg" }
    @{ src = "$Instance\mmc-pack.json";                             entry = "$name/mmc-pack.json" }
    @{ src = "$Instance\minecraft\packwiz-installer-bootstrap.jar"; entry = "$name/minecraft/packwiz-installer-bootstrap.jar" }
    @{ src = "$Instance\minecraft\icon.png";                        entry = "$name/minecraft/icon.png" }
)
if (Test-Path $Out) { Remove-Item -LiteralPath $Out -Force }
$zip = [IO.Compression.ZipFile]::Open($Out, [IO.Compression.ZipArchiveMode]::Create)
try {
    # Explorer renders a zip with no directory entries as an empty folder on some
    # Windows configurations, so write them explicitly.
    foreach ($d in @("$name/", "$name/minecraft/")) { $zip.CreateEntry($d) | Out-Null }
    foreach ($i in $include) {
        if (-not (Test-Path -LiteralPath $i.src)) { Write-Host "  skipped (absent): $($i.entry)" -ForegroundColor DarkYellow; continue }
        [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $i.src, $i.entry) | Out-Null
        Write-Host "  + $($i.entry)"
    }
} finally { $zip.Dispose() }
Remove-Item $tmp -Force

# --- verify before anyone can download it --------------------------------
$check = [IO.Compression.ZipFile]::OpenRead($Out)
$names = @($check.Entries | ForEach-Object { $_.FullName })
$bad   = @($check.Entries | Where-Object { $_.FullName.Contains([char]92) })
$e     = $check.Entries | Where-Object { $_.FullName -eq "$name/instance.cfg" }
$sr    = New-Object IO.StreamReader($e.Open()); $shipped = $sr.ReadToEnd(); $sr.Close()
$check.Dispose()

$fail = @()
if ($bad.Count)                              { $fail += "backslash entry names" }
if ($shipped -notmatch [regex]::Escape($PackUrl)) { $fail += "pack URL missing or wrong" }
if ($shipped -match 'example\.invalid')      { $fail += "placeholder URL present" }
if ($shipped -match 'probe')                 { $fail += "debug probe command present" }
if ($shipped -notmatch 'OverrideCommands=true') { $fail += "OverrideCommands not enabled" }
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
Write-Host "Built and verified: $([math]::Round((Get-Item $Out).Length/1KB)) KB, $($names.Count) files" -ForegroundColor Green
Write-Host "  pack URL: $PackUrl" -ForegroundColor DarkGray
