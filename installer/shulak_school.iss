[Setup]
AppId={{8A2E0F13-8D4B-4B7A-9D8B-6C7B7E6A1405}
AppName=Shalak School
AppVersion=0.1.0
AppPublisher=Shalak Middle School
DefaultDirName={autopf}\Shalak School
DefaultGroupName=Shalak School
UninstallDisplayIcon={app}\shalak_school.exe
OutputDir=..\dist
OutputBaseFilename=ShalakSchool-Setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
ArchitecturesInstallIn64BitMode=x64

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional shortcuts:"; Flags: unchecked

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Shalak School"; Filename: "{app}\shalak_school.exe"
Name: "{autodesktop}\Shalak School"; Filename: "{app}\shalak_school.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\shalak_school.exe"; Description: "Launch Shalak School"; Flags: postinstall nowait skipifsilent
