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

unit TextUtil;

{$MODE OBJFPC}
{$MODESWITCH UNICODESTRINGS}

interface

type
  TStringArray = array of string;

function IntToStr(const I: Integer): string;

function StrToDWORD(S: string; out D: DWORD): Boolean;

function DWORDToStr(const D: DWORD): string;

procedure StrSplit(S, Delim: string; var Dest: TStringArray);

function HexStr(N: LongInt; const C: Byte): string;

function LowercaseString(const S: string): string;

function SameText(const S1, S2: string): Boolean;

implementation

uses
  windows;

function IntToStr(const I: Integer): string;
begin
  Str(I, result);
end;

function StrToDWORD(S: string; out D: DWORD): Boolean;
var
  Code: Word;
begin
  if Copy(S, 1, 2) = '0x' then
    S := '$' + Copy(S, 3, Length(S) - 2);
  Val(S, D, Code);
  result := Code = 0;
end;

function DWORDToStr(const D: DWORD): string;
begin
  Str(D, result);
end;

// Returns the number of times Substring appears in S
function CountSubstring(const Substring, S: string): Integer;
var
  P: Integer;
begin
  result := 0;
  P := Pos(Substring, S, 1);
  while P <> 0 do
  begin
    Inc(result);
    P := Pos(Substring, S, P + Length(Substring));
  end;
end;

// Splits S into the Dest array using Delim as a delimiter
procedure StrSplit(S, Delim: string; var Dest: TStringArray);
var
  I, P: Integer;
begin
  I := CountSubstring(Delim, S);
  // If no delimiters, Dest is a single-element array
  if I = 0 then
  begin
    SetLength(Dest, 1);
    Dest[0] := S;
    exit;
  end;
  SetLength(Dest, I + 1);
  for I := 0 to Length(Dest) - 1 do
  begin
    P := Pos(Delim, S);
    if P > 0 then
    begin
      Dest[I] := Copy(S, 1, P - 1);
      Delete(S, 1, P + Length(Delim) - 1);
    end
    else
      Dest[I] := S;
  end;
end;

function HexStr(N: LongInt; const C: Byte): string;
const
  HexChars: array[0..15] of Char = '0123456789ABCDEF';
var
  I: LongInt;
begin
  SetLength(result, C);
  for I := C downto 1 do
  begin
    result[I] := HexChars[N and $F];
    N := N shr 4;
  end;
end;

function LowercaseString(const S: string): string;
var
  Locale: LCID;
  Len: DWORD;
  pResult: PChar;
begin
  result := '';
  if S = '' then
    exit;
  Locale := MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT);
  Len := LCMapStringW(Locale,  // LCID    Locale
    LCMAP_LOWERCASE,           // DWORD   dwMapFlags
    PChar(S),                  // LPCWSTR lpSrcStr
    -1,                        // int     cchSrc
    nil,                       // LPWSTR  lpDestStr
    0);                        // int     cchDest
  if Len = 0 then
    exit;
  GetMem(pResult, Len * SizeOf(Char));
  if LCMapStringW(Locale,  // LCID    Locale
    LCMAP_LOWERCASE,       // DWORD   dwMapFlags
    PChar(S),              // LPCWSTR lpSrcStr
    -1,                    // int     cchSrc
    pResult,               // LPWSTR  lpDestStr
    Len) > 0 then          // int     cchDest
  begin
    result := string(pResult);
  end;
  FreeMem(pResult);
end;

function SameText(const S1, S2: string): Boolean;
const
  CSTR_EQUAL = 2;
begin
  result := CompareStringW(GetThreadLocale(),  // LCID    Locale
    LINGUISTIC_IGNORECASE,                     // DWORD   dwCmpFlags
    PChar(S1),                                 // PCNZWCH lpString1
    -1,                                        // int     cchCount1
    PChar(S2),                                 // PCNZWCH lpString2
    -1) = CSTR_EQUAL;                          // int     cchCount2
end;

begin
end.
