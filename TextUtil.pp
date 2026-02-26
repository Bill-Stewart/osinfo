{ Copyright (C) 2024-2026 by Bill Stewart (bstewart at iname.com)

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

function StrToDWORD(S: string; out D: DWORD): Boolean;

function DWORDToStr(const D: DWORD): string;

function HexStr(N: DWORD; const C: Byte): string;

implementation

uses
  windows;

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

function HexStr(N: DWORD; const C: Byte): string;
const
  HexChars: array[0..15] of Char = '0123456789ABCDEF';
var
  I: Integer;
begin
  SetLength(result, C);
  for I := C downto 1 do
  begin
    result[I] := HexChars[N and $F];
    N := N shr 4;
  end;
end;

begin
end.
