{ Copyright (C) 2024 by Bill Stewart (bstewart at iname.com)

  This program is free software: you can redistribute it and/or modify it under
  the terms of the GNU General Public License as published by the Free Software
  Foundation, either version 3 of the License, or (at your option) any later
  version.

  This program is distributed in the hope that it will be useful, but WITHOUT
  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
  details.

  You should have received a copy of the GNU General Public License
  along with this program. If not, see https://www.gnu.org/licenses/.

}

unit WindowsMessages;

{$MODE OBJFPC}
{$MODESWITCH UNICODESTRINGS}

interface

uses
  windows;

// For the specified string, replaces '%1' ('%2', etc.) in the string with the
// values from the Args array; if the Args array contains an insufficient
// number of elements, the message string is returned unmodified
function FormatMessageInsertArgs(const Msg: string; const Args: array of string): string;

// For the following functions, the parameters are as follows:

// MessageId - the Windows message number [e.g., from GetLastError() function]

// AddId - if true, appends the error number (in decimal) to the end of the
// returned message

// Module - If specified, names a module that the FormatMessage() function
// should search for messages

// Args - If specified, provides an array of arguments that will be used to
// replace the '%1' ('%2', etc.) placeholders in the message string; if the
// Args array contains an insufficient number of elements, the message string
// is returned unmodified

function GetWindowsMessage(const MessageId: DWORD): string;

function GetWindowsMessage(const MessageId: DWORD; const AddId: Boolean): string;

function GetWindowsMessage(const MessageId: DWORD; const Module: string): string;

function GetWindowsMessage(const MessageId: DWORD; const Module: string; const AddId: Boolean): string;

function GetWindowsMessage(const MessageId: DWORD; const Args: array of string): string;

function GetWindowsMessage(const MessageId: DWORD; const AddId: Boolean; const Args: array of string): string;

function GetWindowsMessage(const MessageId: DWORD; const Module: string;
  const Args: array of string): string;

function GetWindowsMessage(const MessageId: DWORD; const Module: string; const AddId: Boolean;
  const Args: array of string): string;

implementation

function FormatMessageFromSystem(const MessageId: DWORD; const AddId: Boolean = false;
  const Module: string = ''): string;
var
  MsgFlags: DWORD;
  ModuleHandle: HMODULE;
  pBuffer: PChar;
  StrID: string;
begin
  MsgFlags := FORMAT_MESSAGE_MAX_WIDTH_MASK or
    FORMAT_MESSAGE_ALLOCATE_BUFFER or
    FORMAT_MESSAGE_FROM_SYSTEM or
    FORMAT_MESSAGE_IGNORE_INSERTS;
  ModuleHandle := 0;
  if Module <> '' then
  begin
    ModuleHandle := LoadLibraryExW(PChar(Module),  // LPCWSTR lpLibFileName
      0,                                           // HANDLE hFile
      LOAD_LIBRARY_AS_DATAFILE);                   // DWORD  dwFlags
    if ModuleHandle <> 0 then
      MsgFlags := MsgFlags or FORMAT_MESSAGE_FROM_HMODULE;
  end;
  if FormatMessageW(MsgFlags,                   // DWORD   dwFlags
    Pointer(ModuleHandle),                      // LPCVOID lpSource
    MessageId,                                  // DWORD   dwMessageId
    MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),  // DWORD   dwLanguageId
    @pBuffer,                                   // LPWSTR  lpBuffer
    0,                                          // DWORD   nSize
    nil) > 0 then                               // va_list Arguments
  begin
    result := PChar(pBuffer);
    LocalFree(HLOCAL(pBuffer));  // HLOCAL hMem
    if result[Length(result)] = ' ' then
      SetLength(result, Length(result) - 1);
  end
  else
    result := 'Unknown error';
  if ModuleHandle <> 0 then
    FreeLibrary(ModuleHandle);  // HMODULE hLibModule
  if AddId then
  begin
    Str(MessageId, StrID);
    result := result + ' (' + StrID + ')';
  end;
end;

function FormatMessageInsertArgs(const Msg: string; const Args: array of string): string;
var
  ArgArray: array of DWORD_PTR;
  I, MsgFlags: DWORD;
  pBuffer: PChar;
begin
  result := Msg;
  if High(Args) > -1 then
  begin
    SetLength(ArgArray, High(Args) + 1);
    for I := Low(Args) to High(Args) do
      ArgArray[I] := DWORD_PTR(PChar(Args[I]));
    MsgFlags := FORMAT_MESSAGE_ALLOCATE_BUFFER or
      FORMAT_MESSAGE_FROM_STRING or
      FORMAT_MESSAGE_ARGUMENT_ARRAY;
    try
      if FormatMessageW(MsgFlags,  // DWORD   dwFlags
        PChar(Msg),                // LPCVOID lpSource
        0,                         // DWORD   dwMessageId
        0,                         // DWORD   dwLanguageId
        @pBuffer,                  // LWTSTR  lpBuffer
        0,                         // DWORD   nSize
        @ArgArray[0]) > 0 then     // va_list Arguments
      begin
        result := PChar(pBuffer);
        LocalFree(HLOCAL(pBuffer));  // HLOCAL hMem
      end;
    except
    end;
  end;
end;

function GetWindowsMessage(const MessageId: DWORD): string;
begin
  result := FormatMessageFromSystem(MessageId);
end;

function GetWindowsMessage(const MessageId: DWORD; const AddId: Boolean): string;
begin
  result := FormatMessageFromSystem(MessageId, AddId);
end;

function GetWindowsMessage(const MessageId: DWORD; const Module: string): string;
begin
  result := FormatMessageFromSystem(MessageId, false, Module);
end;

function GetWindowsMessage(const MessageId: DWORD; const Module: string; const AddId: Boolean): string;
begin
  result := FormatMessageFromSystem(MessageId, AddId, Module);
end;

function GetWindowsMessage(const MessageId: DWORD; const Args: array of string): string;
var
  Msg: string;
begin
  Msg := FormatMessageFromSystem(MessageId);
  result := FormatMessageInsertArgs(Msg, Args);
end;

function GetWindowsMessage(const MessageId: DWORD; const AddId: Boolean; const Args: array of string): string;
var
  Msg: string;
begin
  Msg := FormatMessageFromSystem(MessageId, AddId);
  result := FormatMessageInsertArgs(Msg, Args);
end;

function GetWindowsMessage(const MessageId: DWORD; const Module: string;
  const Args: array of string): string;
var
  Msg: string;
begin
  Msg := FormatMessageFromSystem(MessageId, false, Module);
  result := FormatMessageInsertArgs(Msg, Args);
end;

function GetWindowsMessage(const MessageId: DWORD; const Module: string; const AddId: Boolean;
  const Args: array of string): string;
var
  Msg: string;
begin
  Msg := FormatMessageFromSystem(MessageId, AddId, Module);
  result := FormatMessageInsertArgs(Msg, Args);
end;

begin
end.
