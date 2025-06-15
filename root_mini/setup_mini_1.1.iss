[Setup]
AppId={{F3A6B8D2-4E1F-4A3C-9D1B-5E8C9F2A1B7D}
AppName=360游戏大厅
AppVersion=1.1
AppPublisher=Msdzls Team for 360Game 
DefaultDirName={userappdata}\360Game5
DefaultGroupName=360游戏大厅
OutputBaseFilename=360GameSetup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
SetupLogging=yes
SetupIconFile=setupicon.ico
UninstallFilesDir={app}
UninstallDisplayIcon={app}\unins000.exe
UninstallDisplayName=360游戏大厅卸载程序
VersionInfoCopyright=© 360.cn All Rights Reserved.
VersionInfoVersion=7.0.0.1110
ChangesAssociations=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: checkedonce

[Files]
Source: "Res\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs solidbreak
Source: "setupicon.ico"; DestDir: "{app}"; Flags: solidbreak dontcopy

[Icons]
Name: "{group}\360游戏大厅"; Filename: "{app}\bin\360Game.exe"
Name: "{commondesktop}\360游戏大厅"; Filename: "{app}\bin\360Game.exe"; Tasks: desktopicon
Name: "{group}\360游戏大厅卸载程序"; Filename: "{app}\unins000.exe"; IconFilename: "{app}\bin\uninsicon.ico"

[Registry]
Root: HKCU; Subkey: "Software\360Game5"; Flags: deletekey uninsdeletekey
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Uninstall\360Game5"; Flags: deletekey uninsdeletekey

[Run]
Filename: "{app}\Readme.txt"; Description: "查看说明文件"; Flags: postinstall shellexec unchecked

[Code]
var
  UserName: string;
  ShowReadmeCheckBox: TNewCheckBox;

function KillProcessByName(const FileName: string): Boolean;
var
  Code: Integer;
begin
  Result := ShellExec('', 'taskkill.exe', '/F /IM ' + FileName, '', SW_HIDE, ewWaitUntilTerminated, Code);
end;

function DeleteDirectory(const Path: string): Boolean;
var
  FindRec: TFindRec;
  FilePath: string;
begin
  Result := True;
  if FindFirst(Path + '\*', FindRec) then
  begin
    try
      repeat
        if (FindRec.Name <> '.') and (FindRec.Name <> '..') then
        begin
          FilePath := Path + '\' + FindRec.Name;
          if FindRec.Attributes and FILE_ATTRIBUTE_DIRECTORY = 0 then
          begin
            if not DeleteFile(FilePath) then
              Result := False;
          end
          else
          begin
            if not DeleteDirectory(FilePath) then
              Result := False;
          end;
        end;
      until not FindNext(FindRec);
    finally
      FindClose(FindRec);
    end;
  end;
  if Result then
    Result := RemoveDir(Path);
end;

function ReplaceIniString(const FileName, SearchString, ReplaceString: string): Boolean;
var
  Lines: TArrayOfString;
  i: Integer;
  Line: string;
begin
  Result := False;
  if LoadStringsFromFile(FileName, Lines) then
  begin
    for i := 0 to GetArrayLength(Lines) - 1 do
    begin
      Line := Lines[i];
      if StringChangeEx(Line, SearchString, ReplaceString, True) > 0 then
      begin
        Lines[i] := Line;
        Result := True;
      end;
    end;
    if Result then
      Result := SaveStringsToFile(FileName, Lines, False);
  end;
end;

procedure CleanRegistry;
begin
  RegDeleteKeyIncludingSubkeys(HKEY_CURRENT_USER, 'Software\360Game5');
  RegDeleteKeyIncludingSubkeys(HKEY_CURRENT_USER, 'Software\Microsoft\Windows\CurrentVersion\Uninstall\360Game5');  

  // 精确删除Run项中的特定值（不删除其他项）
  if RegValueExists(HKEY_CURRENT_USER,
    'Software\Microsoft\Windows\CurrentVersion\Run', '360Game5') then
  begin
    Log('正在删除开机启动项...');
    RegDeleteValue(HKEY_CURRENT_USER,
      'Software\Microsoft\Windows\CurrentVersion\Run', '360Game5');
  end;
end;

procedure DirectoryCopyForce(SourcePath, DestPath: string);
var
  FindRec: TFindRec;
  SourceFilePath, DestFilePath: string;
begin
  if FindFirst(SourcePath + '\*', FindRec) then
  begin
    try
      repeat
        if (FindRec.Name <> '.') and (FindRec.Name <> '..') then
        begin
          SourceFilePath := SourcePath + '\' + FindRec.Name;
          DestFilePath := DestPath + '\' + FindRec.Name;

          if FindRec.Attributes and FILE_ATTRIBUTE_DIRECTORY = 0 then
          begin
            if FileExists(DestFilePath) then
              DeleteFile(DestFilePath);
            CopyFile(SourceFilePath, DestFilePath, False);
          end
          else
          begin
            ForceDirectories(DestFilePath);
            DirectoryCopyForce(SourceFilePath, DestFilePath);
          end;
        end;
      until not FindNext(FindRec);
    finally
      FindClose(FindRec);
    end;
  end;
end;

function EnsureGame5Suffix(const Path: string): string;
begin
  Result := Path;
  if not (Copy(Result, Length(Result)-7, 8) = '360Game5') then
  begin
    if Result[Length(Result)] = '\' then
      Result := Result + '360Game5'
    else
      Result := Result + '\360Game5';
  end;
end;

procedure HandleSpecialFile(DestPath: string);
var
  SeFile, TargetPath: string;
begin
  SeFile := DestPath + '\360se6.txt';
  TargetPath := ExpandConstant('{%USERPROFILE}\AppData\Roaming\360se6');
  
  if FileExists(SeFile) then
  begin
    Log('正在处理特殊文件...');
    try
      // 确保目标目录存在
      ForceDirectories(ExtractFilePath(TargetPath));
      
      // 复制前删除已有文件
      if FileExists(TargetPath) then
        DeleteFile(TargetPath);
        
      if CopyFile(SeFile, TargetPath, False) then
        Log('文件复制成功')
      else
        Log('文件复制失败');
    except
      Log('处理特殊文件时发生异常');
    end;
  end;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  case CurUninstallStep of
    usPostUninstall:
      begin
        KillProcessByName('360Game.exe');
        CleanRegistry;
        // 删除bin目录
        DelTree(ExpandConstant('{%USERPROFILE}\AppData\Roaming\360Game5\bin'), True, True, True);
        DelTree(ExpandConstant('{app}\bin'), True, True, True);
        // 删除卸载程序自身
        DeleteFile(ExpandConstant('{uninstallexe}'));
      end;
  end;
end;

procedure InitializeWizard;
begin
  UserName := GetUserNameString();
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;

  if CurPageID = wpFinished then
  begin
    // 根据复选框状态设置是否运行说明文件
    WizardForm.RunList.Checked[0] := ShowReadmeCheckBox.Checked;
  end;
  
end;

procedure CleanUpBeforeInstall;
var
  BinPath, SessionPath, DesktopPath: string;
  ShouldCleanSession: Boolean;
begin
  // 强制结束进程
  KillProcessByName('360Game.exe');

  // 删除旧的bin目录
  BinPath := ExpandConstant('{%USERPROFILE}\AppData\Roaming\360Game5\bin');
  if DirExists(BinPath) then
    DeleteDirectory(BinPath);

  // 检测注册表项决定是否清理session
  ShouldCleanSession := RegKeyExists(HKEY_CURRENT_USER,
    'Software\Microsoft\Windows\CurrentVersion\Uninstall\360Game5');

  if ShouldCleanSession then
  begin
    SessionPath := ExpandConstant('{%USERPROFILE}\AppData\Roaming\360Game5\session');
    if DirExists(SessionPath) then
    begin
      Log('已找到卸载注册表项，正在清理session文件夹...');
      DelTree(SessionPath, True, True, True);
    end;
  end;

  // 安装前清理注册表
  CleanRegistry;
  
  // 删除桌面快捷方式
  DesktopPath := ExpandConstant('{%USERPROFILE}\Desktop\360游戏大厅.lnk');
  if FileExists(DesktopPath) then
  begin
      Log('正在删除桌面快捷方式...');
      DeleteFile(DesktopPath);
  end;
end;

procedure InstallFiles;
var
  DestPath, DataPath, AppDataPath: string;
  IsDefaultInstall: Boolean;
begin
  // 确保安装路径以360Game5结尾
  DestPath := EnsureGame5Suffix(ExpandConstant('{app}'));
  DataPath := DestPath + '\data';
  AppDataPath := ExpandConstant('{%USERPROFILE}\AppData\Roaming\360Game5\data');
  
  // 判断是否为默认安装位置
  IsDefaultInstall := SameText(DestPath, ExpandConstant('{userappdata}\360Game5'));
  
  // 替换INI文件中的用户名
  if FileExists(DataPath + '\360Game.ini') then
    if CompareText(UserName, 'Administrator') <> 0 then
      ReplaceIniString(DataPath + '\360Game.ini', 'Administrator', UserName);

  // 添加360se6占用文件	
  HandleSpecialFile(ExpandConstant('{app}'));

  // 如果不是默认安装位置，才需要移动data文件
  if not IsDefaultInstall then
  begin
    ForceDirectories(AppDataPath);
    DirectoryCopyForce(DataPath, AppDataPath);
    DeleteDirectory(DestPath + '\data');
  end;
  
  // 在完成页面添加自定义复选框
  ShowReadmeCheckBox := TNewCheckBox.Create(WizardForm);
  ShowReadmeCheckBox.Parent := WizardForm.FinishedPage;
  ShowReadmeCheckBox.Left := WizardForm.RunList.Left;
  ShowReadmeCheckBox.Top := WizardForm.RunList.Top;
  ShowReadmeCheckBox.Width := WizardForm.RunList.Width;
  ShowReadmeCheckBox.Caption := '查看说明文件 (推荐)';
  ShowReadmeCheckBox.Checked := True; // 默认勾选
  ShowReadmeCheckBox.Visible := True;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  case CurStep of
    ssInstall: 
      begin
        // 在安装文件前执行清理
        CleanUpBeforeInstall;
      end;
    ssPostInstall: 
      begin
        // 文件复制完成后再执行版本覆盖
        InstallFiles;
      end;
  end;
end;

procedure CurPageChanged(CurPageID: Integer);
begin
  if CurPageID = wpFinished then
  begin
    WizardForm.FinishedLabel.Caption := '360游戏大厅 安装已完成！' + #13#10#13#10 +
      '重要提示：关闭大厅游戏窗口时可能会被问是否添加桌面快捷方式，' + #13#10 +
      '切记一定要选"取消"，以防其添加右下角托盘图标。';
	WizardForm.FinishedLabel.Height := ScaleY(120);
  end;
end;
