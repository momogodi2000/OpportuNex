<#
.SYNOPSIS
  Builds Opportunex for Windows x64: engine (PyInstaller), desktop (Flutter release), portable ZIP and installer.

.DESCRIPTION
  Output in dist/windows/:
    Opportunex/                         ready-to-run folder (opportunex.exe + engine/ + licences)
    Opportunex-<version>-windows-x64-portable.zip
    Opportunex-Setup-<version>-x64.exe  (Inno Setup 6, unless -SkipInstaller)
    SHA256SUMS.txt
  Binaries are not code-signed yet (decision D-12).

.EXAMPLE
  .\packaging\windows\build.ps1
  .\packaging\windows\build.ps1 -SkipInstaller
#>
param(
    [switch]$SkipInstaller,
    [string]$InnoSetup = "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe"
)
$ErrorActionPreference = "Stop"

# Native tools write progress to stderr; Windows PowerShell 5.1 would turn that into terminating errors.
function Invoke-Native([string]$What, [scriptblock]$Command) {
    $previous = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try { & $Command 2>&1 | ForEach-Object { "$_" } | Out-Host } finally { $ErrorActionPreference = $previous }
    if ($LASTEXITCODE -ne 0) { throw "$What failed (exit code $LASTEXITCODE)" }
}

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$Desktop = Join-Path $Root "apps\desktop"
$Python = Join-Path $Root "engine\.venv\Scripts\python.exe"
$Dist = Join-Path $Root "dist\windows"
$App = Join-Path $Dist "Opportunex"

$Version = ((Select-String -Path (Join-Path $Desktop "pubspec.yaml") -Pattern '^version:\s*([0-9.]+)').Matches[0].Groups[1].Value)
Write-Host "Opportunex $Version — Windows x64 build" -ForegroundColor Cyan

if (-not (Test-Path $Python)) { throw "engine/.venv is missing: run .\launch-dev.ps1 -Setup first" }

# 1. Engine -----------------------------------------------------------------------------------
Write-Host "[1/5] Engine (PyInstaller)…"
Invoke-Native "PyInstaller" {
    & $Python -m PyInstaller (Join-Path $Root "packaging\engine\opportunex-engine.spec") `
        --distpath (Join-Path $Root "build\engine") --workpath (Join-Path $Root "build\engine-work") --noconfirm --log-level ERROR
}
$EngineExe = Join-Path $Root "build\engine\opportunex-engine\opportunex-engine.exe"
$SelfTestDir = Join-Path $env:TEMP ("opx-selftest-" + [guid]::NewGuid())
$env:OPX_DATA_DIR = $SelfTestDir
try { Invoke-Native "Packaged engine self-test" { & $EngineExe --self-test } }
finally {
    Remove-Item Env:OPX_DATA_DIR
    Remove-Item -Recurse -Force $SelfTestDir -ErrorAction SilentlyContinue
}

# 2. Desktop ----------------------------------------------------------------------------------
Write-Host "[2/5] Desktop (Flutter release)…"
Push-Location $Desktop
try {
    Invoke-Native "flutter pub get" { flutter pub get }
    Invoke-Native "flutter build" { flutter build windows --release }
} finally { Pop-Location }

# 3. Assemble ---------------------------------------------------------------------------------
Write-Host "[3/5] Assembling $App…"
if (Test-Path $Dist) { Remove-Item -Recurse -Force $Dist }
New-Item -ItemType Directory -Force $App | Out-Null
Copy-Item -Recurse (Join-Path $Desktop "build\windows\x64\runner\Release\*") $App
New-Item -ItemType Directory -Force (Join-Path $App "engine") | Out-Null
Copy-Item -Recurse (Join-Path $Root "build\engine\opportunex-engine\*") (Join-Path $App "engine")
$Lic = Join-Path $App "licenses"
New-Item -ItemType Directory -Force $Lic | Out-Null
foreach ($f in "LICENSE", "NOTICE", "THIRD_PARTY_NOTICES.md", "TRADEMARKS.md", "CHANGELOG.md") {
    Copy-Item (Join-Path $Root $f) $Lic
}
Copy-Item -Recurse (Join-Path $Root "packaging\licenses\*") $Lic

# 4. Portable ZIP -----------------------------------------------------------------------------
Write-Host "[4/5] Portable ZIP…"
$Zip = Join-Path $Dist "Opportunex-$Version-windows-x64-portable.zip"
Compress-Archive -Path $App -DestinationPath $Zip -CompressionLevel Optimal

# 5. Installer --------------------------------------------------------------------------------
if (-not $SkipInstaller) {
    Write-Host "[5/5] Installer (Inno Setup)…"
    if (-not (Test-Path $InnoSetup)) { throw "Inno Setup 6 not found at $InnoSetup" }
    Invoke-Native "Inno Setup" {
        & $InnoSetup /Q "/DAppVersion=$Version" "/DSourceDir=$App" "/DOutputDir=$Dist" (Join-Path $PSScriptRoot "opportunex.iss")
    }
} else { Write-Host "[5/5] Installer skipped" }

Get-ChildItem $Dist -File | ForEach-Object {
    "{0}  {1}" -f (Get-FileHash $_.FullName -Algorithm SHA256).Hash.ToLower(), $_.Name
} | Set-Content -Encoding ascii (Join-Path $Dist "SHA256SUMS.txt")
Write-Host "Done: $Dist" -ForegroundColor Green
Get-ChildItem $Dist -File | Format-Table Name, @{n = "MB"; e = { [math]::Round($_.Length / 1MB, 1) } }
