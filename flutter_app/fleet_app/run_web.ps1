# run_web.ps1 — Launch Flutter web without OneDrive lock issues
# Usage: .\run_web.ps1

Write-Host "Preparing Flutter web run..." -ForegroundColor Cyan

# 1. Pause OneDrive
Get-Process OneDrive -ErrorAction SilentlyContinue | ForEach-Object {
    & "$($_.Path)" /pause 2>$null
}

# 2. Kill Chrome + Dart leftovers
Get-Process chrome, dart, dartaotruntime -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 1

# 3. Nuke build folder so Flutter starts clean
$build = "$PSScriptRoot\build"
if (Test-Path $build) {
    $tmp = [System.IO.Path]::GetTempPath() + "empty_" + [System.Guid]::NewGuid()
    New-Item -ItemType Directory $tmp | Out-Null
    robocopy $tmp $build /MIR /NFL /NDL /NJH /NJS /NC /NS 2>$null | Out-Null
    Remove-Item -Recurse -Force $build  -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Force $tmp    -ErrorAction SilentlyContinue
    Write-Host "Build folder cleared." -ForegroundColor Green
}

# 4. Run Flutter
Write-Host "Starting flutter run -d chrome..." -ForegroundColor Cyan
flutter run -d chrome
