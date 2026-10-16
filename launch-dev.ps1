<#
.SYNOPSIS
  Development launcher for Opportunex (Windows).

.DESCRIPTION
  The desktop app supervises the engine itself (arch §3.4): in debug builds it starts
  engine\.venv\Scripts\python.exe engine\main.py, sends a fresh random token on stdin and
  reads the port from stdout. This script only prepares the environment, optionally runs
  the quality checks, then starts `flutter run`.

.PARAMETER Setup       Create engine\.venv and install dependencies if missing.
.PARAMETER Checks      Run ruff, mypy, pytest, flutter analyze and flutter test first (fail fast).
.PARAMETER EngineOnly  Start only the engine with a random token, printing port and token,
                       for API exploration (http://127.0.0.1:<port>/api/v1/docs).
#>
param(
    [switch]$Setup,
    [switch]$Checks,
    [switch]$EngineOnly
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Engine = Join-Path $Root "engine"
$Desktop = Join-Path $Root "apps\desktop"
$Python = Join-Path $Engine ".venv\Scripts\python.exe"

if (-not (Test-Path $Python)) {
    if (-not $Setup) {
        Write-Error "engine\.venv is missing. Run: .\launch-dev.ps1 -Setup"
    }
    Write-Host "Creating engine virtual environment..."
    py -3 -m venv (Join-Path $Engine ".venv")
}
if ($Setup) {
    & $Python -m pip install --upgrade pip
    & $Python -m pip install -r (Join-Path $Engine "requirements-dev.txt")
    if ($LASTEXITCODE -ne 0) { throw "pip install failed" }
    Push-Location $Desktop
    try { flutter pub get; if ($LASTEXITCODE -ne 0) { throw "flutter pub get failed" } }
    finally { Pop-Location }
}

if ($Checks) {
    Push-Location $Engine
    try {
        & $Python -m ruff check .;  if ($LASTEXITCODE -ne 0) { throw "ruff failed" }
        & $Python -m mypy .;        if ($LASTEXITCODE -ne 0) { throw "mypy failed" }
        & $Python -m pytest -q;     if ($LASTEXITCODE -ne 0) { throw "engine tests failed" }
    } finally { Pop-Location }
    Push-Location $Desktop
    try {
        flutter analyze;            if ($LASTEXITCODE -ne 0) { throw "flutter analyze failed" }
        flutter test;               if ($LASTEXITCODE -ne 0) { throw "flutter tests failed" }
    } finally { Pop-Location }
}

if ($EngineOnly) {
    $bytes = New-Object byte[] 32
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
    $token = [Convert]::ToBase64String($bytes).TrimEnd('=').Replace('+', '-').Replace('/', '_')
    Write-Host "Engine token (send as X-Engine-Token): $token"
    Push-Location $Engine
    try { $token | & $Python main.py } finally { Pop-Location }
    exit $LASTEXITCODE
}

Push-Location $Desktop
try { flutter run -d windows } finally { Pop-Location }
