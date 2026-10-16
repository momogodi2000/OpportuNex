<#
.SYNOPSIS
  Captures the real Opportunex installer pages for the user guide (Windows PowerShell 5.1).

.DESCRIPTION
  Runs the Inno Setup installer in French, walks through its pages with Windows UI Automation, and saves each
  page with PrintWindow. Only the installer's own windows are captured, never the rest of the screen.
  Fields showing a path that contains the Windows user name are pixelated.
  It then starts the installed application on a throw-away data folder and captures its window, and finally
  uninstalls silently. A silent uninstall never deletes user data.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File documentation\user-guide\tools\capture_installer.ps1
#>
param(
    [string]$Setup = "dist\windows\Opportunex-Setup-1.0.0-x64.exe",
    [string]$Out = "documentation\user-guide\screenshots"
)
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName UIAutomationClient, UIAutomationTypes, System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class OpxWin {
    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr hdc, uint flags);
    [DllImport("user32.dll")] public static extern IntPtr SendMessage(IntPtr h, uint msg, IntPtr w, IntPtr l);
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
}
"@
[OpxWin]::SetProcessDPIAware() | Out-Null
New-Item -ItemType Directory -Force $Out | Out-Null
$UIA = [System.Windows.Automation.AutomationElement]
$Tree = [System.Windows.Automation.TreeScope]
$True_ = [System.Windows.Automation.Condition]::TrueCondition

function Get-Windows([int[]]$ProcessIds) {
    $UIA::RootElement.FindAll($Tree::Children, $True_) |
        Where-Object { $ProcessIds -contains $_.Current.ProcessId -and $_.Current.Name }
}

function Wait-Window([scriptblock]$Pids, [scriptblock]$Match, [int]$Seconds = 60) {
    $end = (Get-Date).AddSeconds($Seconds)
    while ((Get-Date) -lt $end) {
        $w = Get-Windows (& $Pids) | Where-Object $Match | Select-Object -First 1
        if ($w) { Start-Sleep -Milliseconds 800; return $w }
        Start-Sleep -Milliseconds 300
    }
    throw "window not found"
}

function Find-Control($Window, [string]$Like, [int]$Seconds = 30, [string]$Class = "TNewButton") {
    $end = (Get-Date).AddSeconds($Seconds)
    while ((Get-Date) -lt $end) {
        $c = $Window.FindAll($Tree::Descendants, $True_) |
            Where-Object { $_.Current.ClassName -eq $Class -and $_.Current.Name -like $Like -and $_.Current.IsEnabled -and -not $_.Current.IsOffscreen } |
            Select-Object -First 1
        if ($c) { return $c }
        Start-Sleep -Milliseconds 300
    }
    throw "control '$Like' not found"
}

# Inno Setup's controls (TNewButton, TNewRadioButton, TNewCheckBox) are Win32 buttons without UI Automation
# patterns: press them with BM_CLICK and read check boxes with BM_GETCHECK.
function Invoke-Control($Element) {
    [OpxWin]::SendMessage([IntPtr]$Element.Current.NativeWindowHandle, 0x00F5, [IntPtr]::Zero, [IntPtr]::Zero) | Out-Null
    Start-Sleep -Milliseconds 900
}

function Test-Checked($Element) {
    [OpxWin]::SendMessage([IntPtr]$Element.Current.NativeWindowHandle, 0x00F0, [IntPtr]::Zero, [IntPtr]::Zero) -eq [IntPtr]1
}

function Save-Window($Window, [string]$Name, [object[]]$Mask = @()) {
    $h = [IntPtr]$Window.Current.NativeWindowHandle
    $r = New-Object OpxWin+RECT
    [OpxWin]::GetWindowRect($h, [ref]$r) | Out-Null
    $bmp = New-Object System.Drawing.Bitmap ($r.Right - $r.Left), ($r.Bottom - $r.Top)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $hdc = $g.GetHdc()
    [OpxWin]::PrintWindow($h, $hdc, 2) | Out-Null
    $g.ReleaseHdc($hdc)
    foreach ($el in $Mask) {
        # Pixelate the element (it shows a path containing the Windows user name).
        $b = $el.Current.BoundingRectangle
        $rect = New-Object System.Drawing.Rectangle ([int]$b.X - $r.Left), ([int]$b.Y - $r.Top), ([int]$b.Width), ([int]$b.Height)
        $small = New-Object System.Drawing.Bitmap ([Math]::Max(1, [int]($rect.Width / 9))), ([Math]::Max(1, [int]($rect.Height / 9)))
        $gs = [System.Drawing.Graphics]::FromImage($small)
        $gs.DrawImage($bmp, (New-Object System.Drawing.Rectangle 0, 0, $small.Width, $small.Height), $rect, [System.Drawing.GraphicsUnit]::Pixel)
        $gs.Dispose()
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
        $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
        $g.DrawImage($small, $rect)
        $small.Dispose()
    }
    $g.Dispose()
    $path = Join-Path $Out "$Name.png"
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Host "saved $path"
}

# The application launched at the end of setup inherits this environment: it uses a throw-away data folder,
# never the real %APPDATA%\PIO.
$data = Join-Path ([IO.Path]::GetTempPath()) ("opx-guide-" + [Guid]::NewGuid().ToString("N"))
$env:OPX_DATA_DIR = $data
$appDir = Join-Path $env:LOCALAPPDATA "Programs\Opportunex"
if (Test-Path (Join-Path $appDir "opportunex.exe")) { throw "Opportunex is already installed in ${appDir}: uninstall it first." }

$setupName = [IO.Path]::GetFileNameWithoutExtension($Setup)
$setupPids = { @(Get-Process | Where-Object { $_.Name -like "$setupName*" } | ForEach-Object Id) }
Start-Process -FilePath $Setup -ArgumentList "/LANG=fr"

# 1. Install mode (per user or for all users). Its choices are task-dialog command links, which UI Automation
#    cannot press: capture it, close that run, and start again with the per-user choice made on the command line.
$mode = Wait-Window $setupPids { $true }
Save-Window $mode "install_01_mode"
& $setupPids | ForEach-Object { Stop-Process -Id $_ -Force }
Start-Sleep -Seconds 2
Start-Process -FilePath $Setup -ArgumentList "/LANG=fr", "/CURRENTUSER"

# 2. Licence.
$wizard = Wait-Window $setupPids { $_.Current.ClassName -eq "TWizardForm" }
Save-Window $wizard "install_02_license"
Invoke-Control (Find-Control $wizard "*accepte*" 30 "TNewRadioButton")
Start-Sleep -Milliseconds 500
Invoke-Control (Find-Control $wizard "Suivant*")

# 3. Destination folder (path pixelated: it contains the user name).
$dirEdit = $wizard.FindAll($Tree::Descendants, $True_) |
    Where-Object { $_.Current.ClassName -eq "TEdit" -and -not $_.Current.IsOffscreen } |
    Select-Object -First 1
Save-Window $wizard "install_03_folder" @($dirEdit)
Invoke-Control (Find-Control $wizard "Suivant*")

# 4. Additional tasks.
Save-Window $wizard "install_04_tasks"
Invoke-Control (Find-Control $wizard "Suivant*")

# 5. Ready to install (summary pixelated: it repeats the path).
$memo = $wizard.FindAll($Tree::Descendants, $True_) |
    Where-Object { $_.Current.ClassName -eq "TNewMemo" -and -not $_.Current.IsOffscreen } |
    Select-Object -First 1
Save-Window $wizard "install_05_ready" @($memo)
Invoke-Control (Find-Control $wizard "Installer")

# 6. Finished: capture and close ("Lancer Opportunex" stays ticked).
$finish = Find-Control $wizard "Terminer" 300
Start-Sleep -Milliseconds 800
Save-Window $wizard "install_06_finished"
Invoke-Control $finish

# 7. The application started by setup (throw-away data folder), first-launch screen.
$appPids = { @(Get-Process -Name opportunex -ErrorAction SilentlyContinue | Where-Object { $_.Path -like "$appDir*" } | ForEach-Object Id) }
$main = Wait-Window $appPids { $_.Current.ClassName -eq "FLUTTER_RUNNER_WIN32_WINDOW" }
Start-Sleep -Seconds 15
Save-Window $main "app_01_first_launch"
& $appPids | ForEach-Object { Stop-Process -Id $_ -Force }
Start-Sleep -Seconds 6

# 8. Silent uninstall (keeps user data by design) and clean-up of the throw-away data folder.
Start-Process -FilePath (Join-Path $appDir "unins000.exe") -ArgumentList "/VERYSILENT", "/SUPPRESSMSGBOXES", "/NORESTART" -Wait
Remove-Item -Recurse -Force $data -ErrorAction SilentlyContinue
Write-Host "uninstalled: $(-not (Test-Path (Join-Path $appDir 'opportunex.exe')))"
