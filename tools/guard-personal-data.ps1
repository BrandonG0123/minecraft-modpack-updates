<#  Refuses to publish if anything player-personal has crept into the pack index.
    The index is what friends actually download, so that is what we check.  #>
param([string]$Pack = "$PSScriptRoot\..")
$ErrorActionPreference = 'Stop'

# Paths that must NEVER ship. Matched case-insensitively against index entries.
$blocked = @(
    '^xaero/', '^XaeroWaypoints', '^XaeroWorldMap', 'config/xaero/',
    'xaerohud\.txt', 'xaeropatreon\.txt', 'xaerominimap\.txt',
    '^saves/', '^screenshots/', '^logs/', '^crash-reports/', '^backups/',
    '^shaderpacks/', '^resourcepacks/', '^schematics/', '^essential/',
    'options\.txt', 'optionsof\.txt', 'optionsshaders\.txt',
    'servers\.dat', 'usercache\.json', 'usernamecache\.json',
    'litematica\.json', 'malilib\.json', 'fzzy_config/keybinds',
    '\.mixin\.out', '^\.cache/', '^\.bobby/', '^\.voxy/', '^data/',
    'chesttracker', 'whereisit', 'notes\.json', 'command_history',
    '\.minecraft', 'accounts\.json', 'TrashSlotSaveState'
)

$index = Join-Path $Pack 'index.toml'
$entries = Select-String -LiteralPath $index -Pattern '^file = "(.+)"$' |
           ForEach-Object { $_.Matches[0].Groups[1].Value }

$hits = @()
foreach ($e in $entries) {
    foreach ($b in $blocked) {
        if ($e -match $b) { $hits += "$e   (matched: $b)"; break }
    }
}

if ($hits.Count) {
    Write-Host ""
    Write-Host "*** BLOCKED - personal data found in the pack index ***" -ForegroundColor Red
    $hits | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    Write-Host ""
    Write-Host "Nothing was pushed. Remove these files from the pack folder and re-run." -ForegroundColor Yellow
    exit 1
}
Write-Host "Personal-data guard: clean ($($entries.Count) files checked)" -ForegroundColor DarkGray
exit 0
