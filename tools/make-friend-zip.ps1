<#  Builds the zip you give your friends.
    Contains only instance.cfg, mmc-pack.json, the icon and the bootstrap jar -
    no mod jars, no personal files. The updater fetches everything else on first launch.
    Entry names use forward slashes: Compress-Archive writes backslashes, which is
    outside the ZIP spec and some importers reject it. #>
param(
    [string]$Instance = "$env:APPDATA\PrismLauncher\instances\Tylers Mods",
    [string]$Out      = "$PSScriptRoot\..\Tylers Mods.zip"
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$name = Split-Path $Instance -Leaf
$include = @(
    @{ src = "$Instance\instance.cfg";                              entry = "$name/instance.cfg" }
    @{ src = "$Instance\mmc-pack.json";                             entry = "$name/mmc-pack.json" }
    @{ src = "$Instance\minecraft\packwiz-installer-bootstrap.jar"; entry = "$name/minecraft/packwiz-installer-bootstrap.jar" }
    @{ src = "$Instance\minecraft\icon.png";                        entry = "$name/minecraft/icon.png" }
)

if (Test-Path $Out) { Remove-Item -LiteralPath $Out -Force }
$zip = [IO.Compression.ZipFile]::Open($Out, [IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($i in $include) {
        if (-not (Test-Path -LiteralPath $i.src)) { Write-Host "  skipped (absent): $($i.entry)" -ForegroundColor DarkYellow; continue }
        [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $i.src, $i.entry) | Out-Null
        Write-Host "  + $($i.entry)"
    }
} finally { $zip.Dispose() }

# verify: entry names must use forward slashes and carry nothing personal
$check = [IO.Compression.ZipFile]::OpenRead($Out)
$bad = @($check.Entries | Where-Object { $_.FullName.Contains([char]92) })
$names = @($check.Entries | ForEach-Object { $_.FullName })
$check.Dispose()
if ($bad.Count) { Write-Host "ERROR: backslash entries present" -ForegroundColor Red; exit 1 }
$leak = @($names | Where-Object { $_ -match 'saves/|screenshots/|shaderpacks/|resourcepacks/|xaero|options\.txt|\.jar$' -and $_ -notmatch 'bootstrap\.jar$' })
if ($leak.Count) { Write-Host "ERROR: personal/mod files in zip: $($leak -join ', ')" -ForegroundColor Red; exit 1 }

Write-Host ""
Write-Host "Built: $Out  ($([math]::Round((Get-Item $Out).Length/1KB)) KB, $($names.Count) files)" -ForegroundColor Green
