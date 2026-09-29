; One setup exe for both PCs. The Release folder (secret.exe and its dlls)
; is copied next to the executable so the app can start without Visual Studio.

#ifndef ReleaseDir
  #define ReleaseDir "..\..\build\windows\x64\runner\Release"
#endif

#ifndef AppVersion
  #define AppVersion "1.0.0"
#endif

[Setup]
AppId={{7E4A9C21-6B18-4F0D-9A55-2C8E1D0B7A64}
AppName=Секрет
AppVersion={#AppVersion}
AppPublisher=Секрет
DefaultDirName={localappdata}\Secret
DisableProgramGroupPage=yes
OutputDir=..\..\dist
OutputBaseFilename=secret-setup-{#AppVersion}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
UninstallDisplayIcon={app}\secret.exe
CloseApplications=yes
RestartApplications=no

[Files]
Source: "{#ReleaseDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\Секрет"; Filename: "{app}\secret.exe"
Name: "{autodesktop}\Секрет"; Filename: "{app}\secret.exe"

[Run]
Filename: "{app}\secret.exe"; Description: "Запустить Секрет"; Flags: nowait postinstall skipifsilent
