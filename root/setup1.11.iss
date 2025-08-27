[Setup]
AppId={{F3A6B8D2-4E1F-4A3C-9D1B-5E8C9F2A1B7D}
AppName=360游戏大厅修复版
AppVersion=1.11
AppPublisher=Msdzls Open Source Project
DefaultDirName={userappdata}\360Game5
DefaultGroupName=360游戏大厅修复版
OutputBaseFilename=360Game4Msdzls_v5-6_v1.11
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
SetupLogging=yes
SetupIconFile=setupicon.ico
UninstallFilesDir={app}
UninstallDisplayIcon={app}\unins000.exe
UninstallDisplayName=360游戏大厅修复版卸载程序
VersionInfoCopyright=© 360.cn All Rights Reserved.
VersionInfoVersion=5.2.0.1259
ChangesAssociations=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: checkedonce

[Files]
Source: "Res\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs solidbreak
Source: "setupicon.ico"; DestDir: "{app}"; Flags: solidbreak dontcopy

[Icons]
Name: "{group}\360游戏大厅修复版"; Filename: "{app}\bin\360Game.exe"
Name: "{userdesktop}\360游戏大厅"; Filename: "{app}\bin\360Game.exe"; Tasks: desktopicon
Name: "{group}\360游戏大厅修复版卸载程序"; Filename: "{app}\unins000.exe"; IconFilename: "{app}\bin\uninsicon.ico"

[Registry]
Root: HKCU; Subkey: "Software\360Game5"; Flags: deletekey uninsdeletekey
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Uninstall\360Game5"; Flags: deletekey uninsdeletekey

[Run]
Filename: "{app}\Readme.txt"; Description: "查看说明文件"; Flags: postinstall shellexec unchecked

[Code]
var
  InstallTypePage: TWizardPage;
  InstallTypeRadioButton1, InstallTypeRadioButton2: TNewRadioButton;
  VersionPage, FlashVersionPage, CompatModePage: TWizardPage;
  VersionRadioButton1, VersionRadioButton2: TNewRadioButton;
  FlashRadioButton1, FlashRadioButton2, FlashRadioButton3: TNewRadioButton;
  CompatModeCheckBox: TNewCheckBox;
  SelectedVersion, SelectedFlashVersion, UserName: string;
  CustomInstall: Boolean;
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

procedure ForceDeleteDirectory(Path: string);
var
  FindRec: TFindRec;
begin
  if FindFirst(Path + '\*', FindRec) then
  try
    repeat
      if (FindRec.Name <> '.') and (FindRec.Name <> '..') then
      begin
        if FindRec.Attributes and FILE_ATTRIBUTE_DIRECTORY <> 0 then
          ForceDeleteDirectory(Path + '\' + FindRec.Name)
        else
          DeleteFile(Path + '\' + FindRec.Name);
      end;
    until not FindNext(FindRec);
  finally
    FindClose(FindRec);
  end;
  RemoveDir(Path);
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
        // 删除bin和flash目录
        DelTree(ExpandConstant('{%USERPROFILE}\AppData\Roaming\360Game5\bin'), True, True, True);
        DelTree(ExpandConstant('{app}\bin'), True, True, True);
        DelTree(ExpandConstant('{app}\flash'), True, True, True);
        // 删除卸载程序自身
        DeleteFile(ExpandConstant('{uninstallexe}'));
      end;
  end;
end;

procedure InitializeWizard;
var
  Label1: TLabel;
  UserProfilePath: string;
begin
  // 获取真实的用户目录名（从%USERPROFILE%环境变量）
  UserProfilePath := ExpandConstant('{%USERPROFILE}');
  // 提取目录名（去除路径分隔符）
  UserName := ExtractFileName(RemoveBackslash(UserProfilePath));

  // 安装类型选择页面
  InstallTypePage := CreateCustomPage(wpWelcome, '选择安装类型', '请选择安装方式：');
  
  Label1 := TLabel.Create(InstallTypePage);
  Label1.Parent := InstallTypePage.Surface;
  Label1.Caption := '标准安装将使用推荐配置快速安装，自定义安装可手动选择各项参数。';
  Label1.AutoSize := False;
  Label1.WordWrap := True;
  Label1.Width := InstallTypePage.SurfaceWidth;
  Label1.Height := ScaleY(40);
  
  InstallTypeRadioButton1 := TNewRadioButton.Create(InstallTypePage);
  InstallTypeRadioButton1.Parent := InstallTypePage.Surface;
  InstallTypeRadioButton1.Top := Label1.Top + Label1.Height + ScaleY(10);
  InstallTypeRadioButton1.Width := InstallTypePage.SurfaceWidth;
  InstallTypeRadioButton1.Caption := '标准安装 (推荐) - V5版本 + Flash 25版本';
  InstallTypeRadioButton1.Checked := True;
  
  InstallTypeRadioButton2 := TNewRadioButton.Create(InstallTypePage);
  InstallTypeRadioButton2.Parent := InstallTypePage.Surface;
  InstallTypeRadioButton2.Top := InstallTypeRadioButton1.Top + InstallTypeRadioButton1.Height + ScaleY(5);
  InstallTypeRadioButton2.Width := InstallTypePage.SurfaceWidth;
  InstallTypeRadioButton2.Caption := '自定义安装 - 手动选择大厅版本和Flash版本';

  // 版本选择页面
  VersionPage := CreateCustomPage(InstallTypePage.ID, '选择安装版本', '请选择360游戏大厅版本：');
  
  Label1 := TLabel.Create(VersionPage);
  Label1.Parent := VersionPage.Surface;
  Label1.Caption := 'V5版本为旧版UI且键鼠记忆等模块有一定缺陷；V6版本为新版UI且更通用，但不支持兼容模式Flash。';
  Label1.AutoSize := False;
  Label1.WordWrap := True;
  Label1.Width := VersionPage.SurfaceWidth;
  Label1.Height := ScaleY(40);
  
  VersionRadioButton1 := TNewRadioButton.Create(VersionPage);
  VersionRadioButton1.Parent := VersionPage.Surface;
  VersionRadioButton1.Top := Label1.Top + Label1.Height + ScaleY(10);
  VersionRadioButton1.Width := VersionPage.SurfaceWidth;
  VersionRadioButton1.Caption := 'V5版本 (旧版UI，支持兼容模式)';
  VersionRadioButton1.Checked := True;
  
  VersionRadioButton2 := TNewRadioButton.Create(VersionPage);
  VersionRadioButton2.Parent := VersionPage.Surface;
  VersionRadioButton2.Top := VersionRadioButton1.Top + VersionRadioButton1.Height + ScaleY(5);
  VersionRadioButton2.Width := VersionPage.SurfaceWidth;
  VersionRadioButton2.Caption := 'V6版本 (新版UI，通用性更好)';

  // Flash版本选择页面
  FlashVersionPage := CreateCustomPage(VersionPage.ID, '选择Flash版本', 'Flash Player版本选择');
  
  Label1 := TLabel.Create(FlashVersionPage);
  Label1.Parent := FlashVersionPage.Surface;
  Label1.Caption := '13版本：官方早期稳定版本；25版本：极速模式默认版本；34版本：CleanFlash较新版本。注意：兼容模式仅支持13和34版本，选择25时将自动适配34版本。';
  Label1.AutoSize := False;
  Label1.WordWrap := True;
  Label1.Width := FlashVersionPage.SurfaceWidth;
  Label1.Height := ScaleY(60);
  
  FlashRadioButton1 := TNewRadioButton.Create(FlashVersionPage);
  FlashRadioButton1.Parent := FlashVersionPage.Surface;
  FlashRadioButton1.Top := Label1.Top + Label1.Height + ScaleY(10);
  FlashRadioButton1.Width := FlashVersionPage.SurfaceWidth;
  FlashRadioButton1.Caption := 'Flash 13版本';
  
  FlashRadioButton2 := TNewRadioButton.Create(FlashVersionPage);
  FlashRadioButton2.Parent := FlashVersionPage.Surface;
  FlashRadioButton2.Top := FlashRadioButton1.Top + FlashRadioButton1.Height + ScaleY(5);
  FlashRadioButton2.Width := FlashVersionPage.SurfaceWidth;
  FlashRadioButton2.Caption := 'Flash 25版本 (默认)';
  FlashRadioButton2.Checked := True;
  
  FlashRadioButton3 := TNewRadioButton.Create(FlashVersionPage);
  FlashRadioButton3.Parent := FlashVersionPage.Surface;
  FlashRadioButton3.Top := FlashRadioButton2.Top + FlashRadioButton2.Height + ScaleY(5);
  FlashRadioButton3.Width := FlashVersionPage.SurfaceWidth;
  FlashRadioButton3.Caption := 'Flash 34版本';

  // 兼容模式选择页面
  CompatModePage := CreateCustomPage(FlashVersionPage.ID, '启用兼容模式', '是否启用兼容模式');
  
  CompatModeCheckBox := TNewCheckBox.Create(CompatModePage);
  CompatModeCheckBox.Parent := CompatModePage.Surface;
  CompatModeCheckBox.Width := CompatModePage.SurfaceWidth;
  CompatModeCheckBox.Caption := '启用兼容模式 (仅V5版本有效)';
  CompatModeCheckBox.Checked := True;
end;

function ShouldSkipPage(PageID: Integer): Boolean;
begin
  // 如果是标准安装，跳过所有选择页面
  if not CustomInstall then
  begin
    if (PageID = VersionPage.ID) or 
       (PageID = FlashVersionPage.ID) or 
       (PageID = CompatModePage.ID) then
      Result := True
    else
      Result := False;
  end
  else
  begin
    // 自定义安装时，V6版本跳过兼容模式页面
    if (PageID = CompatModePage.ID) and (SelectedVersion = 'V6') then
      Result := True
    else
      Result := False;
  end;
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;

  if CurPageID = wpFinished then
  begin
    // 根据复选框状态设置是否运行说明文件
    WizardForm.RunList.Checked[0] := ShowReadmeCheckBox.Checked;
  end;
  
  if CurPageID = InstallTypePage.ID then
  begin
    CustomInstall := InstallTypeRadioButton2.Checked;
    
    // 设置标准安装的默认值
    if not CustomInstall then
    begin
      SelectedVersion := 'V5';
      SelectedFlashVersion := '25';
      CompatModeCheckBox.Checked := False;
    end;
  end
  else if CurPageID = VersionPage.ID then
  begin
    if VersionRadioButton1.Checked then
      SelectedVersion := 'V5'
    else
      SelectedVersion := 'V6';
  end
  else if CurPageID = FlashVersionPage.ID then
  begin
    if FlashRadioButton1.Checked then
      SelectedFlashVersion := '13'
    else if FlashRadioButton2.Checked then
      SelectedFlashVersion := '25'
    else
      SelectedFlashVersion := '34';
  end;
end;

function ShouldCleanSession: Boolean;
var
  RegExists, VersionDirExists: Boolean;
  PathsToCheck: TArrayOfString;
  i: Integer;
begin
  // 条件1：检测注册表项是否存在
  RegExists := RegKeyExists(HKEY_CURRENT_USER,
    'Software\Microsoft\Windows\CurrentVersion\Uninstall\360Game5');

  // 条件2：检测版本目录是否存在
  SetArrayLength(PathsToCheck, 2);
  PathsToCheck[0] := ExpandConstant('{%USERPROFILE}\AppData\Roaming\360Game5\bin\7.0.0.1110\360');
  PathsToCheck[1] := ExpandConstant('{app}\bin\7.0.0.1110\360');

  VersionDirExists := False;
  for i := 0 to GetArrayLength(PathsToCheck) - 1 do
  begin
    if DirExists(PathsToCheck[i]) then
    begin
      VersionDirExists := True;
      Break;
    end;
  end;

  // 任意条件满足即返回True
  Result := RegExists or VersionDirExists;
end;

procedure CleanUpBeforeInstall;
var
  BinPath, AppBinPath, SessionPath, DesktopPath: string;
begin
  // 强制结束进程
  KillProcessByName('360Game.exe');

  // 若满足对应条件，则清理session目录
  if ShouldCleanSession then
  begin
    SessionPath := ExpandConstant('{%USERPROFILE}\AppData\Roaming\360Game5\session');
    if DirExists(SessionPath) then
    begin
      ForceDeleteDirectory(SessionPath);
      Log('条件满足，正在清理session文件夹...');
    end
    else
      Log('session文件夹不存在，无需清理');
  end
  else
    Log('清理条件未满足，跳过session文件夹清理');

  // 安装前清理注册表
  CleanRegistry;

  // 删除旧的bin目录
  BinPath := ExpandConstant('{%USERPROFILE}\AppData\Roaming\360Game5\bin');
  if DirExists(BinPath) then
    ForceDeleteDirectory(BinPath);
  AppBinPath := ExpandConstant('{app}\bin');
  if DirExists(AppBinPath) then
	ForceDeleteDirectory(AppBinPath);
  
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
  DestPath, DataPath, FlashFile, FlashOCX, TargetFlash, AppDataPath: string;
  ResultCode: Integer;
  IsDefaultInstall: Boolean;
begin
  // 确保安装路径以360Game5结尾
  DestPath := EnsureGame5Suffix(ExpandConstant('{app}'));
  DataPath := DestPath + '\data';
  AppDataPath := ExpandConstant('{%USERPROFILE}\AppData\Roaming\360Game5\data');
  
  // 判断是否为默认安装位置
  IsDefaultInstall := SameText(DestPath, ExpandConstant('{userappdata}\360Game5'));
  
  // 安装公共文件
  begin
    DirectoryCopyForce(DestPath + '\common', DestPath);
    Log('已安装公共文件');
  end;
  
  // 根据选择覆盖版本特有文件
  if SelectedVersion = 'V5' then
  begin
    DirectoryCopyForce(DestPath + '\v5', DestPath);
    Log('已覆盖V5版本特有文件');
  end
  else
  begin
    DirectoryCopyForce(DestPath + '\v6', DestPath);
    Log('已覆盖V6版本特有文件');
  end;
  
  // 替换INI文件中的用户名（使用真实的用户目录名）
  if FileExists(DataPath + '\360Game.ini') then
    if CompareText(UserName, 'Administrator') <> 0 then
      ReplaceIniString(DataPath + '\360Game.ini', 'Administrator', UserName);
	  
  // 处理Flash文件
  case SelectedFlashVersion of
    '13': TargetFlash := 'NPSWF13.dll';
    '25': TargetFlash := 'NPSWF25.dll';
    '34': TargetFlash := 'NPSWF34.dll';
  end;
  
  FlashFile := DestPath + '\flash\' + TargetFlash;
  if FileExists(FlashFile) then
    CopyFile(FlashFile, DataPath + '\NPSWF.dll', False);

  // 添加360se6占用文件	
  HandleSpecialFile(ExpandConstant('{app}'));

  // 处理兼容模式（仅V5版本）
  if (SelectedVersion = 'V5') then
  begin
    case SelectedFlashVersion of
      '13': FlashOCX := 'Flash13.ocx';
      '25', '34': FlashOCX := 'Flash34.ocx';
    end;
    
    if FileExists(DestPath + '\flash\' + FlashOCX) then
      CopyFile(DestPath + '\flash\' + FlashOCX, DataPath + '\Flash.ocx', False);
  end;
  
  if (SelectedVersion = 'V5') and CompatModeCheckBox.Checked then
  begin
    if FileExists(DestPath + '\flash\AXsetup.exe') then
      Exec(DestPath + '\flash\AXsetup.exe', '', '', SW_SHOW, ewWaitUntilTerminated, ResultCode);
  end;

  // 如果不是默认安装位置，才需要移动data文件
  if not IsDefaultInstall then
  begin
    ForceDirectories(AppDataPath);
    DirectoryCopyForce(DataPath, AppDataPath);
    ForceDeleteDirectory(DestPath + '\data');
  end;
  
  // 安装完成后删除版本目录
  ForceDeleteDirectory(DestPath + '\v5');
  ForceDeleteDirectory(DestPath + '\v6');
  ForceDeleteDirectory(DestPath + '\common');
  
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
      '切记一定要选"取消"，以防其在之后出现危险弹窗。';
	WizardForm.FinishedLabel.Height := ScaleY(120);
  end;
end;
