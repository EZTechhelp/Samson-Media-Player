; Script generated by the Inno Setup Script Wizard.
; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!

#define MyAppName "EZT-MediaPlayer"
#define MyAppVersion "0.3.9"
#define MyAppPublisher "EZTechhelp"
#define MyAppURL "https://www.EZTechhelp.com/"
#define MyAppExeName "EZT-MediaPlayer.exe"

[Setup]
; NOTE: The value of AppId uniquely identifies this application. Do not use the same AppId value in installers for other applications.
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
AppId={{4C8E33BE-7E0A-4970-A7EC-B70180A6CD8E}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
;AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={commonpf}\{#MyAppName}
DisableProgramGroupPage=yes
InfoBeforeFile=.\CHANGELOG.rtf
InfoAfterFile=.\README.rtf
; Remove the following line to run in administrative install mode (install for all users.)
;PrivilegesRequired=lowest
OutputBaseFilename=EZT-MediaPlayer-Setup
OutputDir=.\Builds\
SetupIconFile=.\Setup\MusicPlayerFilltest.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern
CloseApplications=yes
SetupLogging=yes
BackColor=clBlack
BackColor2=clBlack
ShowTasksTreeLines=yes
AppendDefaultDirName=no
LicenseFile=.\License_English.rtf
UserInfoPage=no
[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: ".\Launcher\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: ".\{#MyAppName}.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: ".\Version.txt"; DestDir: "{app}"; Flags: ignoreversion
Source: ".\Assembly\*"; DestDir: "{app}\Assembly"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: ".\Modules\*"; DestDir: "{app}\Modules"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: ".\Resources\*"; DestDir: "{app}\Resources"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: ".\Views\*"; DestDir: "{app}\Views"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: ".\License_English.rtf"; Flags: dontcopy
Source: ".\license2_english.txt"; Flags: dontcopy
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Code]
var
  LicenseLinkLabel: TLabel;

var
  SecondLicensePage: TOutputMsgMemoWizardPage;
  License2AcceptedRadio: TRadioButton;
  License2NotAcceptedRadio: TRadioButton;

procedure CheckLicense2Accepted(Sender: TObject);
begin
  // Update Next button when user (un)accepts the license
  WizardForm.NextButton.Enabled := License2AcceptedRadio.Checked;
end;

function CloneLicenseRadioButton(Source: TRadioButton): TRadioButton;
begin
  Result := TRadioButton.Create(WizardForm);
  Result.Parent := SecondLicensePage.Surface;
  Result.Caption := Source.Caption;
  Result.Left := 8;
  Result.Top := Source.Top + 75;
  Result.Width := Source.Width;
  Result.Height := Source.Height;
  Result.OnClick := @CheckLicense2Accepted;
end;

procedure InitializeWizard();
var
  LicenseFileName: string;
  LicenseFilePath: string;
var
#ifndef UNICODE
  rtfstr: string;
#else
  rtfstr: AnsiString;
#endif

begin
    LicenseLinkLabel := TLabel.Create(WizardForm);
  LicenseLinkLabel.Parent := WizardForm;
  LicenseLinkLabel.Left := 8;
  LicenseLinkLabel.Top := WizardForm.ClientHeight - 
    LicenseLinkLabel.ClientHeight - 8;
  LicenseLinkLabel.Cursor := crHand;
  LicenseLinkLabel.Font.Color := clBlue;
  LicenseLinkLabel.Font.Style := [fsUnderline];
  LicenseLinkLabel.Caption := 'Pre-Alpha Agreement';
  // Create second license page, with the same labels as the original license page
  SecondLicensePage :=
    CreateOutputMsgMemoPage(
      wpLicense, SetupMessage(msgWizardLicense), SetupMessage(msgLicenseLabel),
      SetupMessage(msgLicenseLabel3), '');

  // Shrink license box to make space for radio buttons
  SecondLicensePage.RichEditViewer.Height := WizardForm.LicenseMemo.Height - 8;

  // Load license
  // Loading ex-post, as Lines.LoadFromFile supports UTF-8,
  // contrary to LoadStringFromFile.
  LicenseFileName := 'license2_english.txt';
  ExtractTemporaryFile(LicenseFileName);
  LicenseFilePath := ExpandConstant('{tmp}\' + LicenseFileName);
  SecondLicensePage.RichEditViewer.Lines.LoadFromFile(LicenseFilePath);
  //LoadStringFromFile( LicenseFileName, rtfstr);
  //SecondLicensePage.RichEditViewer.UseRichEdit := True;
  //SecondLicensePage.RichEditViewer.RTFText := rtfstr;

  DeleteFile(LicenseFilePath);

  // Clone accept/do not accept radio buttons for the second license
  License2AcceptedRadio :=
    CloneLicenseRadioButton(WizardForm.LicenseAcceptedRadio);
  License2NotAcceptedRadio :=
    CloneLicenseRadioButton(WizardForm.LicenseNotAcceptedRadio);

  // Initially not accepted
  License2NotAcceptedRadio.Checked := True;
end;

procedure CurPageChanged(CurPageID: Integer);
begin
  // Update Next button when user gets to second license page
  if CurPageID = SecondLicensePage.ID then
  begin
    CheckLicense2Accepted(nil);
  end;
end;

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: shellexec postinstall skipifsilent runascurrentuser