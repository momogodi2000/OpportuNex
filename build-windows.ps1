$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "Building Windows x64 release..."

# Build engine (We need to package the engine into an executable or isolated env)
# For now, we'll just install requirements into a local .venv that gets shipped, or use PyInstaller.
Write-Host "Setting up Python environment for distribution..."
$EngineDir = Join-Path $ProjectRoot "engine"
$DistVenv = Join-Path $EngineDir "dist-venv"

if (Test-Path $DistVenv) { Remove-Item -Recurse -Force $DistVenv }
python -m venv $DistVenv
& "$DistVenv\Scripts\python.exe" -m pip install -r "$EngineDir\requirements.txt"

# Build frontend
Write-Host "Building Flutter Windows app..."
$FrontendDir = Join-Path $ProjectRoot "apps\desktop"
Push-Location $FrontendDir
flutter pub get
flutter build windows --release
Pop-Location

# Combine into a dist folder
$DistDir = Join-Path $ProjectRoot "build\windows-dist"
if (Test-Path $DistDir) { Remove-Item -Recurse -Force $DistDir }
New-Item -ItemType Directory -Path $DistDir | Out-Null

$FlutterBuildDir = Join-Path $FrontendDir "build\windows\x64\runner\Release"
Copy-Item -Recurse -Force "$FlutterBuildDir\*" $DistDir

$EngineDistDir = Join-Path $DistDir "engine"
New-Item -ItemType Directory -Path $EngineDistDir | Out-Null
Copy-Item -Recurse -Force "$EngineDir\*" $EngineDistDir -Exclude ".venv", "tests", "__pycache__"

Write-Host "Windows build finished in $DistDir. You can use InnoSetup or MSIX to package this folder."
