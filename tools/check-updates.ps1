<#  Read-only. Reports which shipped mods have a newer version on Modrinth.
    Changes nothing - update mods in Prism, then run publish.bat. #>
param([string]$Pack = "$PSScriptRoot\..")
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$UA = @{ 'User-Agent' = 'packwiz-setup/1.0' }
$mcVer = (Select-String -LiteralPath "$Pack\pack.toml" -Pattern '^minecraft = "(.+)"$').Matches[0].Groups[1].Value
Write-Host "Checking Modrinth for updates (Minecraft $mcVer, fabric)..." -ForegroundColor Cyan

$outdated = @(); $checked = 0
foreach ($f in Get-ChildItem "$Pack\mods" -Filter *.pw.toml) {
    $txt = [IO.File]::ReadAllText($f.FullName)
    if ($txt -notmatch 'mod-id = "(.+?)"') { continue }
    $proj = $Matches[1]
    if ($txt -notmatch 'version = "(.+?)"') { continue }
    $curVer = $Matches[1]
    $curFile = if ($txt -match 'filename = "(.+?)"') { $Matches[1] } else { $f.BaseName }
    try {
        $uri = "https://api.modrinth.com/v2/project/$proj/version?loaders=%5B%22fabric%22%5D&game_versions=%5B%22$mcVer%22%5D"
        $vs = Invoke-RestMethod -Uri $uri -Headers $UA
    } catch { continue }
    $checked++
    if ($vs -and $vs.Count -gt 0 -and $vs[0].id -ne $curVer) {
        $outdated += [pscustomobject]@{ Mod = ($f.BaseName -replace '\.pw$',''); Have = $curFile; Latest = $vs[0].files[0].filename }
    }
    Start-Sleep -Milliseconds 120
}
Write-Host ""
if ($outdated.Count -eq 0) { Write-Host "All $checked mods are on the latest version for $mcVer." -ForegroundColor Green }
else {
    Write-Host "$($outdated.Count) of $checked mods have a newer version:" -ForegroundColor Yellow
    $outdated | Sort-Object Mod | Format-Table -AutoSize | Out-String | Write-Host
    Write-Host "To apply: Prism -> your instance -> Mods tab -> Check for updates -> select -> Update." -ForegroundColor Cyan
    Write-Host "Then run publish.bat to ship them." -ForegroundColor Cyan
}
