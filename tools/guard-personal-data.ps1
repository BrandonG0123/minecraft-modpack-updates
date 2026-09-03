<#  Refuses to publish if genuinely private data has crept into a pack index.
    The index is what friends download, so that is what gets checked.

    Both packs legitimately ship mods, configs, shaders and resource packs.
    What must NEVER ship is data that is personal to Tyler specifically:
    waypoints, worlds, screenshots, account data, caches.

    -Mode plus additionally permits options.txt and the personal client configs,
    which the plus pack ships on purpose as first-launch seeds.
#>
param(
    [string]$Pack = "$PSScriptRoot\..",
    [ValidateSet('base','plus')][string]$Mode = 'base'
)
$ErrorActionPreference = 'Stop'

# Never ship from either pack. These identify Tyler or his worlds.
$blocked = @(
    '^xaero/', '^XaeroWaypoints', '^XaeroWorldMap', 'world-map/',
    '^saves/', '^screenshots/', '^logs/', '^crash-reports/', '^backups/',
    '^schematics/', '^essential/', '^data/', '^downloads/',
    '^\.cache/', '^\.bobby/', '^\.voxy/', '\.mixin\.out',
    'usercache\.json', 'usernamecache\.json', 'accounts\.json',
    'command_history', 'TrashSlotSaveState', 'servers\.dat_old',
    'debug-profile\.json', '^\.fabric/', 'Distant_Horizons_server_data'
)
# Personal-but-shippable: base keeps these out, plus ships them as seeds.
$baseOnlyBlocked = @(
    'options\.txt', 'optionsof\.txt', 'optionsshaders\.txt',
    'litematica\.json', 'malilib\.json', 'xaerohud\.txt'
)
if ($Mode -eq 'base') { $blocked += $baseOnlyBlocked }

# Shipped on purpose despite matching a pattern above.
$allowed = @( 'servers.dat' )

$index = Join-Path $Pack 'index.toml'
$entries = Select-String -LiteralPath $index -Pattern '^file = "(.+)"$' |
           ForEach-Object { $_.Matches[0].Groups[1].Value }

$hits = @()
foreach ($e in $entries) {
    if ($allowed -contains $e) { continue }
    foreach ($b in $blocked) {
        if ($e -match $b) { $hits += "$e   (matched: $b)"; break }
    }
}

if ($hits.Count) {
    Write-Host ""
    Write-Host "*** BLOCKED [$Mode] - private data found in the pack index ***" -ForegroundColor Red
    $hits | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    Write-Host ""
    Write-Host "Nothing was pushed. Remove these from the pack folder and re-run." -ForegroundColor Yellow
    exit 1
}
Write-Host "Guard [$Mode]: clean ($($entries.Count) files checked)" -ForegroundColor DarkGray
exit 0
