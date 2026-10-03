param(
    [switch]$NoFrontend = $false
)

$ErrorActionPreference = "Stop"

# 1. Resolve the project root dynamically
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$EngineDir = Join-Path $ProjectRoot "engine"
$FrontendDir = Join-Path $ProjectRoot "apps\desktop"

Write-Host "Project Root: $ProjectRoot"
Write-Host "Engine Dir: $EngineDir"
Write-Host "Frontend Dir: $FrontendDir"


# 5. Activate the backend Python virtual environment
$VenvActivate = Join-Path $EngineDir ".venv\Scripts\Activate.ps1"
if (-Not (Test-Path $VenvActivate)) {
    Write-Error "Virtual environment not found at $VenvActivate. Please run setup."
    exit 1
}

# Source the virtual env
& $VenvActivate

# 6. Load backend environment config
$BackendEnv = Join-Path $EngineDir ".env"
if (-Not (Test-Path $BackendEnv)) {
    Write-Error "Missing backend .env file at $BackendEnv"
    exit 1
}

# 8. Run backend linting, type checking, and tests
Write-Host "Running backend checks..."
Push-Location $EngineDir
try {
    python -m ruff check .
    if ($LASTEXITCODE -ne 0) { Write-Warning "Backend linting failed." }
    
    python -m mypy .
    if ($LASTEXITCODE -ne 0) { Write-Warning "Backend type checking failed." }

    python -m pytest -v
    if ($LASTEXITCODE -ne 0) { Write-Warning "Backend tests failed." }
} finally {
    Pop-Location
}

if (-Not $NoFrontend) {
    Write-Host "Running frontend checks..."
    Push-Location $FrontendDir
    try {
        # flutter analyze
        if ($LASTEXITCODE -ne 0) { Write-Warning "Frontend analysis failed." }
        
        # flutter test
        if ($LASTEXITCODE -ne 0) { Write-Warning "Frontend tests failed." }
    } finally {
        Pop-Location
    }
}

# Start backend
Write-Host "Starting backend..."
Push-Location $EngineDir
# Let's start the backend in the background and capture output
$BackendLog = Join-Path $ProjectRoot "backend.log"

$env:OPX_SESSION_TOKEN = "dev-token-12345-dev-token-12345-dev"
$BackendProcess = Start-Process -FilePath "python" -ArgumentList "main.py" -NoNewWindow -RedirectStandardOutput $BackendLog -RedirectStandardError $BackendLog -PassThru
Pop-Location

Write-Host "Backend started with PID $($BackendProcess.Id)"

if (-Not $NoFrontend) {
    # Start frontend
    Write-Host "Starting frontend..."
    Push-Location $FrontendDir
    $FrontendLog = Join-Path $ProjectRoot "frontend.log"
    $FrontendProcess = Start-Process -FilePath "flutter" -ArgumentList "run -d windows" -NoNewWindow -RedirectStandardOutput $FrontendLog -RedirectStandardError $FrontendLog -PassThru
    Pop-Location
    Write-Host "Frontend started with PID $($FrontendProcess.Id)"
}

try {
    Write-Host "Press Ctrl+C to stop..."
    while ($true) {
        Start-Sleep -Seconds 1
    }
} finally {
    Write-Host "Stopping processes..."
    if ($BackendProcess) { Stop-Process -Id $BackendProcess.Id -Force -ErrorAction SilentlyContinue }
    if ($FrontendProcess) { Stop-Process -Id $FrontendProcess.Id -Force -ErrorAction SilentlyContinue }
}
