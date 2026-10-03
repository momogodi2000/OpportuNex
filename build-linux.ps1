$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "Building Docker image for Linux builder..."
docker build -t opportunex-linux-builder -f Dockerfile.linux-builder .

Write-Host "Running build inside Docker..."
docker run --rm -v "${ProjectRoot}:/app" opportunex-linux-builder bash -c "chmod +x build-deb.sh && ./build-deb.sh"

Write-Host "Linux build finished!"
