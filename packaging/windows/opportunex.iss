; Opportunex — Windows installer (Inno Setup 6).
; Built by packaging\windows\build.ps1, which passes AppVersion, SourceDir and OutputDir.
; Per-user install by default (no administrator rights); per-machine install offered in the first dialog.
; Unsigned until code signing is set up (decision D-12).

#ifndef AppVersion
  #define AppVersion "1.0.0"
#endif
#ifndef SourceDir
  #define SourceDir "..\..\dist\windows\Opportunex"
#endif
#ifndef OutputDir
  #define OutputDir "..\..\dist\windows"
#endif

[Setup]
AppId={{1F5E3C0A-8C77-5A44-9B1E-6D2F0A7E4C31}
AppName=Opportunex
AppVersion={#AppVersion}
AppVerName=Opportunex {#AppVersion}
AppPublisher=ETS Monthe Network
AppPublisherURL=https://github.com/momogodi2000/OpportuNex
AppSupportURL=https://github.com/momogodi2000/OpportuNex/issues
AppCopyright=Copyright (C) 2026 Momo Godi Yvan / ETS Monthe Network
DefaultDirName={autopf}\Opportunex
DefaultGroupName=Opportunex
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
LicenseFile=..\..\LICENSE
OutputDir={#OutputDir}
OutputBaseFilename=Opportunex-Setup-{#AppVersion}-x64
SetupIconFile=..\..\apps\desktop\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\opportunex.exe
UninstallDisplayName=Opportunex
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0.17763
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
CloseApplications=yes
RestartApplications=no
VersionInfoVersion={#AppVersion}
VersionInfoCompany=ETS Monthe Network
VersionInfoProductName=Opportunex
VersionInfoDescription=Opportunex installer

[Languages]
Name: "fr"; MessagesFile: "compiler:Languages\French.isl"
Name: "en"; MessagesFile: "compiler:Default.isl"

[CustomMessages]
fr.DesktopIcon=Créer un raccourci sur le bureau
en.DesktopIcon=Create a desktop shortcut
fr.LaunchApp=Lancer Opportunex
en.LaunchApp=Launch Opportunex
fr.RemoveData=Supprimer aussi vos données Opportunex (profils chiffrés, sauvegardes, journaux) de cet ordinateur ?%n%nRépondez Non pour les conserver (recommandé si vous réinstallez).
en.RemoveData=Also delete your Opportunex data (encrypted profiles, backups, logs) from this computer?%n%nAnswer No to keep it (recommended if you reinstall).

[Tasks]
Name: "desktopicon"; Description: "{cm:DesktopIcon}"; Flags: unchecked

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\Opportunex"; Filename: "{app}\opportunex.exe"
Name: "{autodesktop}\Opportunex"; Filename: "{app}\opportunex.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\opportunex.exe"; Description: "{cm:LaunchApp}"; Flags: nowait postinstall skipifsilent

[Code]
// Optional launch at sign-in is created by the application itself (Preferences); remove it on uninstall.
// User data in %APPDATA%\PIO is kept unless the user explicitly asks to delete it.
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  DataDir: String;
begin
  if CurUninstallStep = usUninstall then
    RegDeleteValue(HKEY_CURRENT_USER, 'Software\Microsoft\Windows\CurrentVersion\Run', 'Opportunex');
  if CurUninstallStep = usPostUninstall then
  begin
    DataDir := ExpandConstant('{userappdata}\PIO');
    if DirExists(DataDir) and (not UninstallSilent) then
      if MsgBox(CustomMessage('RemoveData'), mbConfirmation, MB_YESNO or MB_DEFBUTTON2) = IDYES then
        DelTree(DataDir, True, True, True);
  end;
end;
