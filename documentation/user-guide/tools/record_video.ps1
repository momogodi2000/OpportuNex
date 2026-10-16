<#
.SYNOPSIS
  Records a real Opportunex session (only the application window) to an MP4 file for the user guide.

.DESCRIPTION
  Requires ffmpeg on the PATH (for example: winget install Gyan.FFmpeg). The application is started on a
  throw-away data folder, so no personal profile appears in the recording; create a test profile with fictional
  data during the recording. ffmpeg captures the window titled "Opportunex" (gdigrab) until -Seconds elapse or you
  press q in this console. The data folder is deleted afterwards.

.PARAMETER Name
  File name without extension, e.g. 02_premier_lancement. Suggested set: 01_installation (record the installer
  with -NoLaunch -Title "Installation - Opportunex 1.0.0"), 02_premier_lancement, 03_navigation, 04_recherche,
  05_suivi_candidature, 06_sauvegarde_restauration.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File documentation\user-guide\tools\record_video.ps1 -Name 04_recherche -Seconds 120
#>
param(
    [Parameter(Mandatory = $true)][string]$Name,
    [int]$Seconds = 90,
    [string]$App = "dist\windows\Opportunex\opportunex.exe",
    [string]$Title = "Opportunex",
    [switch]$NoLaunch,
    [string]$Out = "documentation\user-guide\videos"
)
$ErrorActionPreference = "Stop"
$ffmpeg = Get-Command ffmpeg -ErrorAction SilentlyContinue
if (-not $ffmpeg) { throw "ffmpeg is not installed or not on the PATH (winget install Gyan.FFmpeg)." }
New-Item -ItemType Directory -Force $Out | Out-Null

$data = $null
$proc = $null
if (-not $NoLaunch) {
    $data = Join-Path ([IO.Path]::GetTempPath()) ("opx-video-" + [Guid]::NewGuid().ToString("N"))
    $env:OPX_DATA_DIR = $data
    $proc = Start-Process -FilePath $App -PassThru
    Start-Sleep -Seconds 8
}
$target = Join-Path $Out "$Name.mp4"
Write-Host "Recording window '$Title' for $Seconds s into $target (press q to stop earlier)…"
& $ffmpeg.Source -hide_banner -loglevel warning -y -f gdigrab -framerate 20 -draw_mouse 1 -i "title=$Title" `
    -t $Seconds -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" -c:v libx264 -preset veryfast -crf 24 -pix_fmt yuv420p $target
if ($LASTEXITCODE -ne 0) { throw "ffmpeg failed ($LASTEXITCODE)" }
if ($proc) {
    Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 6
    Remove-Item -Recurse -Force $data -ErrorAction SilentlyContinue
}
Write-Host "saved $target"
