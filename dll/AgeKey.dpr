library AgeKey;

uses
  Windows;

{$IFNDEF FPC}
 {$E dll}
{$ENDIF}

const
  UniqueName = 'KeyboardHook_AgeKey_{AA35E2A5-7B53-4de6-A5D0-AAC166208C6D}';
  KeyboardHookWait = True;
  KeyboardHookTime = 500;

type
  PKeyboardHookData = ^TKeyboardHookData;
  TKeyboardHookData = packed record
    Code: Integer;
    WParam: WPARAM;
    LParam: LPARAM;
    Tag: Integer;
  end;

var
  KeyboardHook: HHOOK;
  KeyboardHookMapp: THandle;
  KeyboardHookAddr: TFNHookProc;
  KeyboardHookData: PKeyboardHookData;
  KeyboardHookSend: UINT;

function KeyboardHookInstall: UINT; stdcall;
begin
  Result := 0;
  if (KeyboardHookMapp <> 0) and (KeyboardHookData <> nil) then
    if KeyboardHook = 0 then
    begin
      KeyboardHook := SetWindowsHookEx(WH_KEYBOARD, KeyboardHookAddr, HInstance, 0);
      if KeyboardHook <> 0 then
        Result := KeyboardHookSend;
    end;
end;

function KeyboardHookRelease: BOOL; stdcall;
begin
  Result := False;
  if KeyboardHook <> 0 then
    if UnhookWindowsHookEx(KeyboardHook) then
    begin
      KeyboardHook := 0;
      Result := True;
    end;
end;

function KeyboardHookGetData(var Data: TKeyboardHookData): BOOL; stdcall;
begin
  Result := False;
  if (KeyboardHookMapp <> 0) and Assigned(KeyboardHookData) then
    if KeyboardHook <> 0 then
      if FlushViewOfFile(KeyboardHookData, SizeOf(TKeyboardHookData)) then
      begin
        Data := KeyboardHookData^;
        Result := True;
      end;
end;

function KeyboardHookSetData(const Data: TKeyboardHookData): BOOL; stdcall;
begin
  Result := False;
  if (KeyboardHookMapp <> 0) and Assigned(KeyboardHookData) then
    if KeyboardHook <> 0 then
    begin
      KeyboardHookData^ := Data;
      Result := FlushViewOfFile(KeyboardHookData, SizeOf(TKeyboardHookData));
    end;
end;

function KeyboardHookProc(Code: Integer; WParam: WPARAM; LParam: LPARAM): LRESULT; stdcall;
var
  TimeRun: DWORD;
  TimeNow: DWORD;
  CallNext: BOOL;
begin
  CallNext := True;
  if Code = HC_ACTION then
  begin
    KeyboardHookData^.Code := Integer(BOOL(GetKeyState(VK_CONTROL) and $8000 <> 0));
    KeyboardHookData^.WParam := WParam;
    KeyboardHookData^.LParam := LParam;
    KeyboardHookData^.Tag := 0;
    if FlushViewOfFile(KeyboardHookData, SizeOf(TKeyboardHookData)) then
    begin
      SendMessage(HWND_BROADCAST, KeyboardHookSend, 0, 0);
      if KeyboardHookWait then
      begin
        TimeRun := GetTickCount;
        repeat
          TimeNow := GetTickCount;
          if TimeNow < TimeRun then
            TimeRun := TimeNow;
        until (KeyboardHookData^.Tag <> 0) or (TimeNow - TimeRun > KeyboardHookTime);
        CallNext := KeyboardHookData^.Tag >= 0;
      end;
    end;
  end;
  if CallNext then
    Result := CallNextHookEx(KeyboardHook, Code, WParam, LParam)
  else
    Result := 1;
end;

procedure DllEntry(Reason : DWORD);
begin
  case Reason of
    DLL_PROCESS_ATTACH:
      begin
        DisableThreadLibraryCalls(HInstance);
        KeyboardHookSend := RegisterWindowMessage(UniqueName);
        KeyboardHookAddr := @KeyboardHookProc;
        KeyboardHookMapp := CreateFileMapping($FFFFFFFF, nil, PAGE_READWRITE, 0,
          SizeOf(TKeyboardHookData), UniqueName);
        if KeyboardHookMapp <> 0 then
        begin
          KeyboardHookData := MapViewOfFile(KeyboardHookMapp, FILE_MAP_ALL_ACCESS,
            0, 0, SizeOf(TKeyboardHookData));
          if KeyboardHookData = nil then
            if CloseHandle(KeyboardHookMapp) then
              KeyboardHookMapp := 0;
        end;
      end;
    DLL_PROCESS_DETACH:
      begin
        if KeyboardHookData <> nil then
          if UnmapViewOfFile(KeyboardHookData) then
            KeyboardHookData := nil;
        if (KeyboardHookMapp <> 0) then
          if CloseHandle(KeyboardHookMapp) then
            KeyboardHookMapp := 0;
      end;
  end;
end;

{$IFDEF FPC}
function DLLEntryPoint(dllparam: longint): longbool;
begin
  DllEntry(dllparam);
  result := true;
end;

procedure DLLExitPoint(dllparam : longint);
begin
  DllEntry(DLL_PROCESS_DETACH);
end;
{$ENDIF}

exports
  KeyboardHookInstall name 'Install',
  KeyboardHookRelease name 'Release',
  KeyboardHookGetData name 'GetData',
  KeyboardHookSetData name 'SetData';

{$IFDEF FPC}
begin
     Dll_Process_Attach_Hook := @DLLEntryPoint;
     DLLEntryPoint(DLL_PROCESS_ATTACH);
     Dll_Process_Detach_Hook := @DLLExitPoint;
{$ELSE}
begin
  DllProc := @DLLEntry;
  DllEntry(DLL_PROCESS_ATTACH);
{$ENDIF}
end.

