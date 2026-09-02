<#  Stop shipping a mod to friends. The jar stays in YOUR instance.
    Works by adding the mod to exclude-mods.txt, so the next sync respects it. #>
param([string]$Pack = "$PSScriptRoot\..", [string]$Name, [switch]$Force)
$ErrorActionPreference = 'Stop'
$excludeFile = "$PSScriptRoot\exclude-mods.txt"

Write-Host "Mods currently shipped to your friends:" -ForegroundColor Cyan
$mods = Get-ChildItem "$Pack\mods" -Filter *.pw.toml | ForEach-Object {
    [pscustomobject]@{ Slug = ($_.BaseName -replace '\.pw$','')
                       File = (Select-String -LiteralPath $_.FullName -Pattern '^filename = "(.+)"$').Matches[0].Groups[1].Value }
}
$mods | Sort-Object Slug | Format-Table -AutoSize | Out-String | Write-Host

if (-not $Name) { $Name = Read-Host "Mod to stop shipping (slug or part of the filename)" }
if (-not $Name) { Write-Host "Cancelled."; exit 0 }

$hits = @($mods | Where-Object { $_.Slug -like "*$Name*" -or $_.File -like "*$Name*" })
if ($hits.Count -eq 0) { Write-Host "No mod matched '$Name'. Nothing changed." -ForegroundColor Red; exit 1 }
if ($hits.Count -gt 1) {
    Write-Host "'$Name' matched several mods - be more specific:" -ForegroundColor Yellow
    $hits | ForEach-Object { Write-Host "  $($_.Slug)  ($($_.File))" }
    exit 1
}

$hit = $hits[0]
Write-Host ""
Write-Host "Will stop shipping:  $($hit.Slug)   ->  $($hit.File)" -ForegroundColor Yellow
Write-Host "The jar STAYS in your own instance. Friends lose it on their next launch."
if (-not $Force -and (Read-Host "Type YES to confirm") -ne 'YES') { Write-Host "Cancelled."; exit 0 }

[IO.File]::AppendAllText($excludeFile, $hit.File + "`n")
Remove-Item -LiteralPath "$Pack\mods\$($hit.Slug).pw.toml" -Force
Write-Host "Excluded. Run publish.bat to push the change." -ForegroundColor Green
