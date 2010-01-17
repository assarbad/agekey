program AgeKey;

{$R AgeKey.res}

uses
  Windows, Messages, CommDlg, ShellAPI;

{------------------------------------------------------------------------------}

const
  AgeKeyOneInst = 'AgeKeyOneInst';

var
  AgeKeyOneInstMsg: UINT = 0;
  TaskbarCreatedMsg: UINT = 0;

{------------------------------------------------------------------------------}

const
  DLL_KEYBHOOK = 4444;

  IDI_MAINICON = 1;
  IDD_MAINFORM = 101;
  //IDM_MAINMENU = 102;

  IDM_MENUINFO = 201;
  IDM_MENUPRO1 = 202;
  IDM_MENUPRO2 = 203;
  IDM_MENUPRO3 = 204;
  IDM_MENUPRO4 = 205;
  IDM_MENUPRO5 = 206;
  IDM_MENUPRO6 = 207;
  IDM_MENUPRO7 = 208;
  IDM_MENUPRO8 = 209;

  IDC_KINSTALL = 301;
  IDC_KRELEASE = 302;
  IDC_LOADFILE = 303;
  IDC_SAVEFILE = 304;

  IDC_CHECKCTRL = 401;

  IDC_CHECKF01 = 512;  { VK_F1 + 400 }
  IDC_CHECKF12 = 523;
  //IDC_CHECKF02 = 513;
  //IDC_CHECKF03 = 514;
  //IDC_CHECKF04 = 515;
  //IDC_CHECKF05 = 516;
  //IDC_CHECKF06 = 517;
  //IDC_CHECKF07 = 518;
  //IDC_CHECKF08 = 519;
  //IDC_CHECKF09 = 520;
  //IDC_CHECKF10 = 521;
  //IDC_CHECKF11 = 522;

  IDC_EDITF01 = 612;  { VK_F1 + 500 }
  IDC_EDITF02 = 613;
  IDC_EDITF03 = 614;
  IDC_EDITF04 = 615;
  IDC_EDITF05 = 616;
  IDC_EDITF06 = 617;
  IDC_EDITF07 = 618;
  IDC_EDITF08 = 619;
  IDC_EDITF09 = 620;
  IDC_EDITF10 = 621;
  IDC_EDITF11 = 622;
  IDC_EDITF12 = 623;

{------------------------------------------------------------------------------}

const
  MAX_TEXT = 1024;

const
  DlgTxClr = $00702010;
  DlgBkClr = $00B0C0A0;
  EdtTxClr = $00803020;
  EdtBkClr = $00C0D0B0;
  DlgLogBrush: TLogBrush =(
    lbStyle: BS_SOLID;
    lbColor: DlgBkClr;
    lbHatch: 0;
  );
  EdtLogBrush: TLogBrush =(
    lbStyle: BS_SOLID;
    lbColor: EdtBkClr;
    lbHatch: 0;
  );

var
  DlgBrush: HBRUSH = 0;
  EdtBrush: HBRUSH = 0;

const
  AppTitle = 'AgeKey - Message Helper';

{------------------------------------------------------------------------------}

const
  WM_SHELLNOTIFY = WM_USER + 5;

const
  IDI_MAINTRAY = 0;
  IDM_TRAYREST = 1001;
  IDM_TRAYEXIT = 1002;

const
  TrayRestText = '&Restore';
  TrayExitText = 'E&xit Program';

var
  TrayIconData: TNotifyIconData = (
    cbSize: SizeOf(TNotifyIconData);
{$IFDEF FPC}
    hWnd:
{$ELSE}
    Wnd:
{$ENDIF}
            0;
    uID: IDI_MAINTRAY;
    uFlags: NIF_ICON or NIF_MESSAGE or NIF_TIP;
    uCallbackMessage: WM_SHELLNOTIFY;
    hIcon: 0;
    szTip: AppTitle
  );
  TrayPopupMenu: HMENU = 0;

{------------------------------------------------------------------------------}

type
  //PKeyboardHookData = ^TKeyboardHookData;
  TKeyboardHookData = packed record
    Code: Integer;
    WParam: WPARAM;
    LParam: LPARAM;
    Tag: Integer;
  end;

var
  AgeKeyDllInst: HMODULE = 0;
  AgeKeyDll: array [0..MAX_PATH] of Char;

const
  KeybInstallName = 'Install';
  KeybReleaseName = 'Release';
  KeybGetDataName = 'GetData';
  KeybSetDataName = 'SetData';

type
  TFNKeyboardHookInstall = function: UINT; stdcall;
  TFNKeyboardHookRelease = function: BOOL; stdcall;
  TFNKeyboardHookGetData = function(var Data: TKeyboardHookData): BOOL; stdcall;
  TFNKeyboardHookSetData = function(const Data: TKeyboardHookData): BOOL; stdcall;

var
  KeyboardHookInstall: TFNKeyboardHookInstall = nil;
  KeyboardHookRelease: TFNKeyboardHookRelease = nil;
  KeyboardHookGetData: TFNKeyboardHookGetData = nil;
  KeyboardHookSetData: TFNKeyboardHookSetData = nil;

function InitHookDll: BOOL;
var
  Info: HRSRC;
  Size: Integer;
  Data: Pointer;
  Path: array [0..MAX_PATH] of Char;
  Hand: HFILE;
  BNum: DWORD;
begin
  Result := False;
  Info := FindResource(HInstance, PChar(DLL_KEYBHOOK), 'KEYBHOOK');
  if Info <> 0 then
  begin
    Size := SizeofResource(HInstance, Info);
    Data := LockResource(LoadResource(HInstance, Info));
    if (Data <> nil) and (Size > 0) then
    begin
      ZeroMemory(@Path, SizeOf(Path));
      ZeroMemory(@AgeKeyDll, SizeOf(AgeKeyDll));
      if GetTempPath(MAX_PATH, Path) > 0 then
        if GetTempFileName(Path, 'AKF', 0, AgeKeyDll) > 0 then
        begin
          Hand := CreateFile(AgeKeyDll, GENERIC_WRITE, FILE_SHARE_READ, nil,
            CREATE_ALWAYS, FILE_ATTRIBUTE_ARCHIVE, 0);
          if Hand <> INVALID_HANDLE_VALUE then
          begin
            BNum := 0;
            WriteFile(Hand, Data^, Size, BNum, nil);
            if Integer(BNum) = Size then
            begin
              CloseHandle(Hand);
              Hand := 0;
              AgeKeyDllInst := LoadLibrary(AgeKeyDll);
              if AgeKeyDllInst <> 0 then
              begin
                KeyboardHookInstall := TFNKeyboardHookInstall(GetProcAddress(AgeKeyDllInst, KeybInstallName));
                KeyboardHookRelease := TFNKeyboardHookRelease(GetProcAddress(AgeKeyDllInst, KeybReleaseName));
                KeyboardHookGetData := TFNKeyboardHookGetData(GetProcAddress(AgeKeyDllInst, KeybGetDataName));
                KeyboardHookSetData := TFNKeyboardHookSetData(GetProcAddress(AgeKeyDllInst, KeybSetDataName));
                Result := Assigned(KeyboardHookInstall) and
                  Assigned(KeyboardHookRelease) and
                  Assigned(KeyboardHookGetData) and
                  Assigned(KeyboardHookSetData);
              end;
            end;
          end;
          if not Result then
          begin
            if (Hand <> INVALID_HANDLE_VALUE) and (Hand <> 0) then
              CloseHandle(Hand);
            if AgeKeyDllInst <> 0 then
              FreeLibrary(AgeKeyDllInst);
            DeleteFile(AgeKeyDll);
          end;
        end;
    end;
  end;
  if not Result then
    MessageBox(0, 'Cannot initialize needed library!', AppTitle, MB_ICONERROR);
end;

var
  KeyboardHookSend: UINT;

procedure InstallHook(Dlg: HWND);
begin
  if KeyboardHookSend = 0 then
  begin
    KeyboardHookSend := KeyboardHookInstall();
    if KeyboardHookSend <> 0 then
    begin
      EnableWindow(GetDlgItem(Dlg, IDC_KINSTALL), False);
      EnableWindow(GetDlgItem(Dlg, IDC_KRELEASE), True);
    end
    else
      MessageBox(Dlg, 'Keyboard hook not installed!', AppTitle, MB_ICONERROR);
  end
  else
    MessageBox(Dlg, 'Already activated!', AppTitle, MB_ICONINFORMATION);
end;

procedure ReleaseHook(Dlg: HWND);
begin
  if KeyboardHookSend <> 0 then
  begin
    if KeyboardHookRelease() then
    begin
      KeyboardHookSend := 0;
      EnableWindow(GetDlgItem(Dlg, IDC_KINSTALL), True);
      EnableWindow(GetDlgItem(Dlg, IDC_KRELEASE), False);
    end
    else
      MessageBox(Dlg, 'Keyboard hook not released!', AppTitle, MB_ICONERROR);
  end
  else
    MessageBox(Dlg, 'Not activated!', AppTitle, MB_ICONINFORMATION);
end;

procedure KeybMsgHandler(Dlg: HWND);
var
  Data: TKeyboardHookData;
  Evnt: Boolean;
  Text: array [0..MAX_TEXT] of Char;
  Thrd: DWORD;
  Edit: HWND;
  Name: array [0..MAX_TEXT] of Char;
begin
  if KeyboardHookGetData(Data) then
  begin
    Data.Tag := 0;
    try
      Evnt := BOOL(Data.Code);
      if (Data.WParam >= IDC_CHECKF01 - 400) and
        (Data.WParam <= IDC_CHECKF12 - 400) and
        ((IsDlgButtonChecked(Dlg, IDC_CHECKCTRL) = BST_UNCHECKED) xor Evnt) and
        (IsDlgButtonChecked(Dlg, Data.WParam + 400) = BST_CHECKED) then
      begin
        ZeroMemory(@Text, MAX_TEXT + 1);
        if GetDlgItemText(Dlg, Data.WParam + 500, @Text[0], MAX_TEXT) > 0 then
        begin
          Thrd := GetWindowThreadProcessId(GetForegroundWindow, nil);
          if Thrd <> 0 then
          begin
            if AttachThreadInput(GetCurrentThreadId, Thrd, True) then
            begin
              Edit := GetFocus;
              if Edit <> 0 then
              begin
                Data.Tag := -1;
                KeyboardHookSetData(Data);
                if LoWord(Data.LParam) = 1 then
                begin
                  ZeroMemory(@Name, SizeOf(Name));
                  GetClassName(Edit, Name, MAX_TEXT);
                  if Data.LParam < 0 then
                  begin
                    if lstrcmpi(Name, 'EDIT') = 0 then
                    begin
                      SendMessage(Edit, WM_SETTEXT, 0, Integer(@Text[0]));
                      if Evnt then
                        keybd_event(VK_CONTROL, 0, KEYEVENTF_KEYUP, 0);
                      keybd_event(VK_RETURN, 0, 0, 0);
                      keybd_event(VK_RETURN, 0, KEYEVENTF_KEYUP, 0);
                      if Evnt then
                        keybd_event(VK_CONTROL, 0, 0, 0);
                    end;
                  end
                  else
                  begin
                    if (lstrcmpi(Name, 'EDIT') <> 0) and
                      (Data.LParam and $40000000 = 0) then
                    begin
                      if Evnt then
                        keybd_event(VK_CONTROL, 0, KEYEVENTF_KEYUP, 0);
                      keybd_event(VK_RETURN, 0, 0, 0);
                      keybd_event(VK_RETURN, 0, KEYEVENTF_KEYUP, 0);
                      if Evnt then
                        keybd_event(VK_CONTROL, 0, 0, 0);
                    end;
                  end;
                end;
              end;
              AttachThreadInput(GetCurrentThreadId, Thrd, False);
            end;
          end;
        end;
      end;
    finally
      if Data.Tag = 0 then
      begin
        Data.Tag := 1;
        KeyboardHookSetData(Data);
      end;
    end;
  end;
end;

{------------------------------------------------------------------------------}

procedure ShowInfo(Dlg: HWND);
var
  Msg: TMsgBoxParams;
begin
  Msg.cbSize := SizeOf(TMsgBoxParams);
  Msg.hwndOwner := Dlg;
  Msg.hInstance := HInstance;
  Msg.lpszText := 'This little program does nothing but'#13#10 +
                  'sending an [Enter]Text[Enter] to the'#13#10 +
                  'active program ;)'#13#10#13#10 +
                  'In fact it''s a simple keyboard hook.'#13#10 +
                  'written by nico with Delphi 5'#13#10#13#10 +
                  '... and updated by olli with Delphi 7'#13#10;
  Msg.lpszCaption := AppTitle;
  Msg.dwStyle := MB_USERICON;
  Msg.lpszIcon := PChar(IDI_MAINICON);
  Msg.dwContextHelpId := 0;
  Msg.lpfnMsgBoxCallback := nil;
  Msg.dwLanguageId := 0;
  MessageBoxIndirect(Msg);
end;

procedure SetText(Dlg: HWND; Item: Word; Text: PChar; Chck: Boolean = True);
begin
  SendMessage(GetDlgItem(Dlg, Item), WM_SETTEXT, 0, Integer(Text));
  if Chck then
    CheckDlgButton(Dlg, Item - 100, BST_CHECKED)
  else
    CheckDlgButton(Dlg, Item - 100, BST_UNCHECKED);
end;

procedure LoadAge1Standard(Dlg: HWND);
begin
  SetText(Dlg, IDC_EDITF05, 'woodstock');
  SetText(Dlg, IDC_EDITF06, 'pepperoni pizza');
  SetText(Dlg, IDC_EDITF07, 'coinage');
  SetText(Dlg, IDC_EDITF08, 'quarry');
  SetText(Dlg, IDC_EDITF12, 'home run');
end;

procedure LoadAge1First1(Dlg: HWND);
begin
  SetText(Dlg, IDC_EDITF01, 'no fog');
  SetText(Dlg, IDC_EDITF02, 'reveal map');
  SetText(Dlg, IDC_EDITF03, 'steroids');
  SetText(Dlg, IDC_EDITF04, 'gaia', False);
  SetText(Dlg, IDC_EDITF11, 'bigdaddy');
end;

procedure LoadAge1First2(Dlg: HWND);
begin
  SetText(Dlg, IDC_EDITF09, 'photon man');
  SetText(Dlg, IDC_EDITF10, 'e=mc2 trooper');
end;

procedure LoadAge1Second1(Dlg: HWND);
begin
  SetText(Dlg, IDC_EDITF01, 'flying dutchman');
  SetText(Dlg, IDC_EDITF02, 'big bertha');
  SetText(Dlg, IDC_EDITF03, 'icbm');
  SetText(Dlg, IDC_EDITF04, 'hoyohoyo');
end;

procedure LoadAge1Second2(Dlg: HWND);
begin
  SetText(Dlg, IDC_EDITF09, 'upsidflintmobile');
  SetText(Dlg, IDC_EDITF10, 'medusa');
  SetText(Dlg, IDC_EDITF11, 'jack be nimble');
end;

procedure LoadAge1xFirst2(Dlg: HWND);
begin
  SetText(Dlg, IDC_EDITF09, 'pow!');
  SetText(Dlg, IDC_EDITF10, 'stormbilly');
end;

procedure LoadAge1xSecond2(Dlg: HWND);
begin
  SetText(Dlg, IDC_EDITF09, 'convert this!');
  SetText(Dlg, IDC_EDITF10, 'dark rain');
  SetText(Dlg, IDC_EDITF11, 'king arthur');
end;

procedure LoadAge2Standard(Dlg: HWND);
begin
  SetText(Dlg, IDC_EDITF01, 'marco');
  SetText(Dlg, IDC_EDITF02, 'polo');
  SetText(Dlg, IDC_EDITF03, 'aegis');
  SetText(Dlg, IDC_EDITF04, 'natural wonders', False);
  SetText(Dlg, IDC_EDITF05, 'lumberjack');
  SetText(Dlg, IDC_EDITF06, 'cheese steak jimmy''s');
  SetText(Dlg, IDC_EDITF07, 'robin hood');
  SetText(Dlg, IDC_EDITF08, 'rock on');
  SetText(Dlg, IDC_EDITF09, 'how do you turn this on');
  SetText(Dlg, IDC_EDITF10, 'to smithereens');
  SetText(Dlg, IDC_EDITF12, 'i r winner');
end;

procedure LoadAgeMythStandard(Dlg: HWND);
begin
  SetText(Dlg, IDC_EDITF01, 'ISIS HEAR MY PLEA');
  SetText(Dlg, IDC_EDITF02, 'JUNK FOOD NIGHT');
  SetText(Dlg, IDC_EDITF03, 'TROJAN HORSE FOR SALE');
  SetText(Dlg, IDC_EDITF04, 'ATM OF EREBUS');
  SetText(Dlg, IDC_EDITF05, 'MOUNT OLYMPUS');
  SetText(Dlg, IDC_EDITF06, 'LAY OF THE LAND');
  SetText(Dlg, IDC_EDITF07, 'PANDORAS BOX');
  SetText(Dlg, IDC_EDITF08, 'DIVINE INTERVENTION');
  SetText(Dlg, IDC_EDITF09, 'L33T SUPA H4X0R');
  SetText(Dlg, IDC_EDITF10, 'BAWK BAWK BOOM');
  SetText(Dlg, IDC_EDITF11, 'O CANADA');
  SetText(Dlg, IDC_EDITF12, 'FEAR THE FORAGE');
end;

function LoadCheats(Dlg: HWND; Item: Word): LRESULT;
begin
  Result := LRESULT(True);
  case Item of
    IDM_MENUPRO1:
      begin
        LoadAge1Standard(Dlg);
        LoadAge1First1(Dlg);
        LoadAge1First2(Dlg);
      end;
    IDM_MENUPRO2:
      begin
        LoadAge1Standard(Dlg);
        LoadAge1Second1(Dlg);
        LoadAge1Second2(Dlg);
      end;
    IDM_MENUPRO3:
      begin
        LoadAge1Standard(Dlg);
        LoadAge1First1(Dlg);
        LoadAge1xFirst2(Dlg);
      end;
    IDM_MENUPRO4:
      begin
        LoadAge1Standard(Dlg);
        LoadAge1Second1(Dlg);
        LoadAge1xSecond2(Dlg);
      end;
    IDM_MENUPRO5:
      begin
        LoadAge2Standard(Dlg);
        SetText(Dlg, IDC_EDITF11, 'i love the monkey head');
      end;
    IDM_MENUPRO6:
      begin
        LoadAge2Standard(Dlg);
        SetText(Dlg, IDC_EDITF11, 'furious the monkey boy');
      end;
    IDM_MENUPRO8,
    IDM_MENUPRO7:
      begin
        LoadAgeMythStandard(Dlg);
      end;
  else
    Result := LRESULT(False);
  end;
  if Result <> 0 then
    CheckDlgButton(Dlg, IDC_CHECKCTRL, BST_CHECKED);
end;

function OnMenu(Dlg: HWND; Item: Word): LRESULT;
begin
  Result := LRESULT(True);
  case Item of
    IDM_MENUINFO:
      ShowInfo(Dlg);
    IDM_MENUPRO1..IDM_MENUPRO8:
      Result := LoadCheats(Dlg, Item);
    IDM_TRAYREST:
      begin
        Shell_NotifyIconA(NIM_DELETE, @TrayIconData);
        ShowWindow(Dlg, SW_RESTORE);
      end;
    IDM_TRAYEXIT:
      begin
        Shell_NotifyIconA(NIM_DELETE, @TrayIconData);
        EndDialog(Dlg, 0);
      end;
  else
    Result := LRESULT(False);
  end;
end;

{------------------------------------------------------------------------------}

const
  AgeKeyFileSignature = $4B656741;

type
  //PAgeKeyFileHeader = ^TAgeKeyFileHeader;
  TAgeKeyFileHeader = packed record
    Signatur: DWORD;
    CtrlOn: Boolean;
  end;
  //PAgeKeyFileEntry = ^TAgeKeyFileEntry;
  TAgeKeyFileEntry = packed record
    Checked: Boolean;
    Text: array [0..MAX_TEXT] of Char;
  end;
  //PAgeKeyFile = ^TAgeKeyFile;
  TAgeKeyFile = packed record
    Header: TAgeKeyFileHeader;
    Entrys: array [IDC_CHECKF01..IDC_CHECKF12] of TAgeKeyFileEntry;
  end;

const
  OfnFilter = 'AgeKey Files  (*.akf)'#0'*.akf'#0'All Files  (*.*)'#0'*.*'#0#0;
  OfnDefExt = 'akf';

var
  Ofn: TOpenFilename;
  OfnFile: array [0..MAX_PATH] of Char;

function LoadFromFile(Dlg: HWND): BOOL;
var
  LoadFile: THandle;
  LoadData: TAgeKeyFile;
  LoadLoop: Integer;
  Read: DWORD;
begin
  Result := False;
  ZeroMemory(@Ofn, SizeOf(TOpenFilename));
  Ofn.lStructSize := SizeOf(TOpenFilename);
  Ofn.hWndOwner := Dlg;
  Ofn.hInstance := HInstance;
  Ofn.lpstrFilter := OfnFilter;
  Ofn.nFilterIndex := 1;
  Ofn.lpstrFile := OfnFile;
  Ofn.nMaxFile := MAX_PATH;
  Ofn.Flags := OFN_HIDEREADONLY or OFN_PATHMUSTEXIST or OFN_FILEMUSTEXIST or
    OFN_EXPLORER or OFN_ENABLESIZING;
{$IFDEF FPC}
  if GetOpenFileName(@Ofn) then
{$ELSE}
  if GetOpenFileName(Ofn) then
{$ENDIF}
  begin
    LoadFile := CreateFile(Ofn.lpstrFile, GENERIC_READ, FILE_SHARE_READ or
       FILE_SHARE_WRITE, nil, OPEN_EXISTING, FILE_ATTRIBUTE_ARCHIVE, 0);
    if LoadFile <> INVALID_HANDLE_VALUE then
    try
      ZeroMemory(@LoadData, SizeOf(TAgeKeyFile));
      Read := 0;
      ReadFile(LoadFile, LoadData, SizeOf(TAgeKeyFile), Read, nil);
      if Read = SizeOf(TAgeKeyFile) then
      begin
        if LoadData.Header.Signatur = AgeKeyFileSignature then
        begin
          if LoadData.Header.CtrlOn then
            CheckDlgButton(Dlg, IDC_CHECKCTRL, BST_CHECKED)
          else
            CheckDlgButton(Dlg, IDC_CHECKCTRL, BST_UNCHECKED);
          for LoadLoop := IDC_CHECKF01 to IDC_CHECKF12 do
          begin
            if LoadData.Entrys[LoadLoop].Checked then
              CheckDlgButton(Dlg, LoadLoop, BST_CHECKED)
            else
              CheckDlgButton(Dlg, LoadLoop, BST_UNCHECKED);
            SetDlgItemText(Dlg, LoadLoop + 100, LoadData.Entrys[LoadLoop].Text);
          end;
          Result := True
        end
        else
          MessageBox(Dlg, 'Wrong file signature!', AppTitle, MB_ICONERROR);
      end
      else
        MessageBox(Dlg, 'Cannot read needed data!', AppTitle, MB_ICONERROR);
    except
      { ignore exceptions }
    end
    else
      MessageBox(Dlg, 'Cannot open file!', AppTitle, MB_ICONERROR);
    if LoadFile <> INVALID_HANDLE_VALUE then
      CloseHandle(LoadFile);
  end;
end;

function SaveToFile(Dlg: HWND): BOOL;
var
  SaveFile: THandle;
  Exists: BOOL;
  SaveData: TAgeKeyFile;
  SaveLoop: Integer;
  Written: DWORD;
begin
  Result := False;
  ZeroMemory(@Ofn, SizeOf(TOpenFilename));
  Ofn.lStructSize := SizeOf(TOpenFilename);
  Ofn.hWndOwner := Dlg;
  Ofn.hInstance := HInstance;
  Ofn.lpstrFilter := OfnFilter;
  Ofn.nFilterIndex := 1;
  Ofn.lpstrFile := OfnFile;
  Ofn.nMaxFile := MAX_PATH;
  Ofn.Flags := OFN_OVERWRITEPROMPT or OFN_HIDEREADONLY or OFN_PATHMUSTEXIST or
    OFN_NOREADONLYRETURN or OFN_EXPLORER or OFN_ENABLESIZING;
  Ofn.lpstrDefExt := OfnDefExt;
{$IFDEF FPC}
  if GetSaveFileName(@Ofn) then
{$ELSE}
  if GetSaveFileName(Ofn) then
{$ENDIF}
  begin
    SaveFile := CreateFile(Ofn.lpstrFile, GENERIC_WRITE, FILE_SHARE_READ, nil,
      CREATE_ALWAYS, FILE_ATTRIBUTE_ARCHIVE, 0);
    Exists := GetLastError = ERROR_ALREADY_EXISTS;
    if SaveFile <> INVALID_HANDLE_VALUE then
    try
      ZeroMemory(@SaveData, SizeOf(TAgeKeyFile));
      SaveData.Header.Signatur := AgeKeyFileSignature;
      SaveData.Header.CtrlOn :=
        IsDlgButtonChecked(Dlg, IDC_CHECKCTRL) = BST_CHECKED;
      for SaveLoop := IDC_CHECKF01 to IDC_CHECKF12 do
      begin
        SaveData.Entrys[SaveLoop].Checked :=
          IsDlgButtonChecked(Dlg, SaveLoop) = BST_CHECKED;
        GetDlgItemText(Dlg, SaveLoop + 100,
          SaveData.Entrys[SaveLoop].Text, MAX_TEXT);
      end;
      Written := 0;
      WriteFile(SaveFile, SaveData, SizeOf(SaveData), Written, nil);
      if Written = SizeOf(SaveData) then
        Result := True
      else
        MessageBox(Dlg, 'Cannot write to file!', AppTitle, MB_ICONERROR);
    except
      { ignore exceptions }
    end
    else
      MessageBox(Dlg, 'Cannot create file!', AppTitle, MB_ICONERROR);
    if SaveFile <> INVALID_HANDLE_VALUE then
    begin
      CloseHandle(SaveFile);
      if (not Exists) and (not Result) then
        DeleteFile(Ofn.lpstrFile);
    end;
  end;
end;

function OnButton(Dlg: HWND; Button: Word): LRESULT;
begin
  Result := LRESULT(True);
  case Button of
    IDC_KINSTALL:
      InstallHook(Dlg);
    IDC_KRELEASE:
      ReleaseHook(Dlg);
    IDC_LOADFILE:
      LoadFromFile(Dlg);
    IDC_SAVEFILE:
      SaveToFile(Dlg);
  else
    Result := LRESULT(False);
  end;
end;

{------------------------------------------------------------------------------}

procedure OnInit(Dlg: HWND);
var
  Loop: Integer;
begin
  TaskbarCreatedMsg := RegisterWindowMessage('TaskbarCreated');
  TrayIconData.hIcon := LoadIcon(HInstance, PChar(IDI_MAINICON));
  SendMessage(Dlg, WM_SETICON, ICON_BIG, Integer(TrayIconData.hIcon));
  for Loop := IDC_EDITF01 to IDC_EDITF12 do
    SendMessage(GetDlgItem(Dlg, Loop), EM_SETLIMITTEXT, MAX_TEXT, 0);
  ZeroMemory(@OfnFile, SizeOf(OfnFile));
  TrayPopupMenu := CreatePopupMenu;
  AppendMenu(TrayPopupMenu, MF_STRING, IDM_TRAYREST, TrayRestText);
  AppendMenu(TrayPopupMenu, MF_STRING, IDM_TRAYEXIT, TrayExitText);
end;

function OnColor(Dlg: HWND; Msg: UINT; WParam: WPARAM): HBRUSH;
begin
  if Msg = WM_CTLCOLOREDIT then
  begin
    SetTextColor(WParam, EdtTxClr);
    SetBkColor(WParam, EdtBkClr);
    if EdtBrush = 0 then
      EdtBrush := CreateBrushIndirect(EdtLogBrush);
    Result := EdtBrush;
  end
  else
  begin
    SetTextColor(WParam, DlgTxClr);
    SetBkColor(WParam, DlgBkClr);
    if DlgBrush = 0 then
      DlgBrush := CreateBrushIndirect(DlgLogBrush);
    Result := DlgBrush;
  end;
end;

procedure OnClose(Dlg: HWND);
begin
  EndDialog(Dlg, 0);
end;

procedure OnDestroy(Dlg: HWND);
begin
  if EdtBrush <> 0 then
    DeleteObject(EdtBrush);
  if DlgBrush <> 0 then
    DeleteObject(DlgBrush);
  if TrayPopupMenu <> 0 then
    DestroyMenu(TrayPopupMenu);
end;

function OnSize(Dlg: HWND; WParam: WPARAM; LParam: LPARAM): BOOL;
begin
  Result := True;
  if WParam = SIZE_MINIMIZED then
  begin
{$IFDEF FPC}
    TrayIconData.hWnd
{$ELSE}
    TrayIconData.Wnd
{$ENDIF}
                             := Dlg;
    ShowWindow(Dlg, SW_HIDE);
    Shell_NotifyIconA(NIM_ADD, @TrayIconData);
    Result := True;
  end
  else
    Shell_NotifyIconA(NIM_DELETE, @TrayIconData);
end;

function OnCommand(Dlg: HWND; WParam: WPARAM; LParam: LPARAM): LRESULT;
begin
  Result := LRESULT(False);
  if LParam = 0 then
    Result := OnMenu(Dlg, LoWord(WParam))
  else if HiWord(WParam) = BN_CLICKED then
    Result := OnButton(Dlg, LoWord(WParam));
end;

function OnShellNotify(Dlg: HWND; WParam: WPARAM; LParam: LPARAM): BOOL;
var
  Point: TPoint;
begin
  Result := False;
  if WParam = IDI_MAINTRAY then
  begin
    Result := True;
    case lParam of
      WM_RBUTTONDOWN:
        begin
          GetCursorPos(Point);
          SetForegroundWindow(Dlg);
          TrackPopupMenu(TrayPopupMenu, TPM_RIGHTALIGN or TPM_RIGHTBUTTON,
            Point.x, Point.y, 0, Dlg, nil);
          PostMessage(Dlg, WM_NULL, 0, 0);
        end;
      WM_LBUTTONDBLCLK:
        SendMessage(Dlg, WM_COMMAND, IDM_TRAYREST, 0);
    else
      Result := False;
    end;
  end;
end;

function OnDefault(Dlg: HWND; Msg: UINT; WParam: WPARAM; LParam: LPARAM): BOOL;
begin
  Result := True;
  if (Msg = KeyboardHookSend) and (KeyboardHookSend <> 0) then
    KeybMsgHandler(Dlg)
  else if (Msg = AgeKeyOneInstMsg) and (AgeKeyOneInstMsg <> 0) then
  begin
    ShowWindow(Dlg, SW_RESTORE);
    ShowWindow(Dlg, SW_SHOW);
    SetForegroundWindow(Dlg);
  end
  else if (Msg = TaskbarCreatedMsg) and (TaskbarCreatedMsg <> 0) then
  begin
    if not IsWindowVisible(Dlg) then
      OnSize(Dlg, SIZE_MINIMIZED, 0);
  end
  else
    Result := False;
end;

{------------------------------------------------------------------------------}

function DlgProc(Dlg: HWND; Msg: UINT; WParam: WPARAM; LParam: LPARAM): LRESULT;
  stdcall;
begin
  Result := LRESULT(TRUE);
  case Msg of
    WM_INITDIALOG:
      OnInit(Dlg);
    WM_CTLCOLORMSGBOX..WM_CTLCOLORSTATIC:
      Result := LRESULT(OnColor(Dlg, Msg, WParam));
    WM_CLOSE:
      OnClose(Dlg);
    WM_DESTROY:
      OnDestroy(Dlg);
    WM_SIZE:
      Result := LRESULT(OnSize(Dlg, WParam, LParam));
    WM_COMMAND:
      Result := LRESULT(OnCommand(Dlg, WParam, LParam));
    WM_SHELLNOTIFY:
      Result := LRESULT(OnShellNotify(Dlg, WParam, LParam));
  else
    Result := LRESULT(OnDefault(Dlg, Msg, WParam, LParam));
  end;
end;

{------------------------------------------------------------------------------}

var
  Mutex: THandle;

begin
  AgeKeyOneInstMsg := RegisterWindowMessage(AgeKeyOneInst);
  Mutex := CreateMutex(nil, False, AgeKeyOneInst);
  if GetLastError() <> ERROR_ALREADY_EXISTS then
  begin
    if InitHookDll() then
    begin
      DialogBoxA(HInstance, PChar(IDD_MAINFORM), 0, @DlgProc);
      FreeLibrary(AgeKeyDllInst);
      DeleteFile(AgeKeyDll);
    end;
  end
  else
    SendMessage(HWND_BROADCAST, AgeKeyOneInstMsg, 0, 0);
  if Mutex <> 0 then
    ReleaseMutex(Mutex);
end.

