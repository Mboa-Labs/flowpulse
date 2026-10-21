# Regenere Architecture_v2.png a partir de architecture_v2.html
# Usage : clic droit > "Executer avec PowerShell", ou dans un terminal : .\generer.ps1

$dossier = $PSScriptRoot
$chrome = "C:\Program Files\Google\Chrome\Application\chrome.exe"
$html = "file:///" + ($dossier -replace '\\', '/' -replace ' ', '%20') + "/architecture_v2.html"
$png = Join-Path $dossier "Architecture_v2.png"

Start-Process -FilePath $chrome -Wait -NoNewWindow -ArgumentList @(
  "--headless=new", "--disable-gpu", "--hide-scrollbars", "--force-device-scale-factor=1.15",
  "--window-size=2000,1260", "--screenshot=`"$png`"", $html)

Write-Host "Image generee : $png"
