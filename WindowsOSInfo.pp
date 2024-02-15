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

unit WindowsOSInfo;

{$MODE OBJFPC}
{$MODESWITCH UNICODESTRINGS}

interface

uses
  windows;

const
  // Current known processor architecture values
  PROCESSOR_ARCHITECTURE_INTEL   = 0;
  PROCESSOR_ARCHITECTURE_ARM     = 5;
  PROCESSOR_ARCHITECTURE_IA64    = 6;
  PROCESSOR_ARCHITECTURE_AMD64   = 9;
  PROCESSOR_ARCHITECTURE_ARM64   = 12;
  PROCESSOR_ARCHITECTURE_UNKNOWN = $FFFF;
  // Product type values
  VER_NT_WORKSTATION       = 1;
  VER_NT_DOMAIN_CONTROLLER = 2;
  VER_NT_SERVER            = 3;

type
  TProcessorArchitecture = (
    ProcessorArchitectureX86         = PROCESSOR_ARCHITECTURE_INTEL,
    ProcessorArchitectureARM         = PROCESSOR_ARCHITECTURE_ARM,
    ProcessorArchitectureIA64        = PROCESSOR_ARCHITECTURE_IA64,
    ProcessorArchitectureAMD64       = PROCESSOR_ARCHITECTURE_AMD64,
    ProcessorArchitectureARM64       = PROCESSOR_ARCHITECTURE_ARM64,
    ProcessorArchitectureUnknown     = PROCESSOR_ARCHITECTURE_UNKNOWN);
  TProductType = (
    ProductTypeWorkstation = VER_NT_WORKSTATION,
    ProductTypeServer      = VER_NT_SERVER);
  TWindowsOSInfo = record
    Architecture:   TProcessorArchitecture;
    BuildNumber:      DWORD;
    BuildRevision:    DWORD;
    DisplayVersion:   string;
    DomainController: Boolean;
    DomainMember:     Boolean;
    HomeEdition:      Boolean;
    ProductInfo:      DWORD;
    ProductType:      TProductType;
    ReleaseID:        string;
    RDSServer:        Boolean;
    RDSession:        Boolean;
    VersionNumber:    string;
  end;

function GetWindowsOSInfo(var OSI: TWindowsOSInfo): DWORD;

function TestVersionString(const S: string): Boolean;

function CompareVersionStrings(const V1, V2: string): Integer;

function GetFileVersion(const FileName: string): string;

implementation

uses
  TextUtil,
  WindowsRegistry;

const
  STATUS_SUCCESS = 0;

type
  RTL_OSVERSIONINFOEXW = record
    dwOSVersionInfoSize: ULONG;
    dwMajorVersion:      ULONG;
    dwMinorVersion:      ULONG;
    dwBuildNumber:       ULONG;
    dwPlatformId:        ULONG;
    szCSDVersion:        array[0..127] of WCHAR;
    wServicePackMajor:   USHORT;
    wServicePackMinor:   USHORT;
    wSuiteMask:          USHORT;
    wProductType:        UCHAR;
    wReserved:           UCHAR;
  end;
  TStringArray = array of string;
  TVersionArray = array[0..1] of Word;

// GetVersionEx is good enough to check if Windows Vista/Server 2008 or newer
function IsWindowsNewEnough(): Boolean;
var
  OVI: OSVERSIONINFO;
begin
  result := false;
  OVI.dwOSVersionInfoSize := SizeOf(OSVERSIONINFO);
  if GetVersionEx(OVI) then
    result := (OVI.dwPlatformId = VER_PLATFORM_WIN32_NT) and (OVI.dwMajorVersion >= 6);
end;

function DWORDToStr(const N: DWORD): string;
begin
  Str(N, result);
end;

function StrToInt(const S: string; var I: Integer): Boolean;
var
  Code: Word;
begin
  Val(S, I, Code);
  result := Code = 0;
end;

function StrToWord(const S: string; var W: Word): Boolean;
var
  Code: Word;
begin
  Val(S, W, Code);
  result := Code = 0;
end;

function GetVersionArray(const S: string; var Version: TVersionArray): Boolean;
var
  A: TStringArray;
  ALen, I, Part: Integer;
begin
  result := false;
  StrSplit(S, '.', A);
  ALen := Length(A);
  if ALen > 2 then
    exit;
  if ALen = 1 then
  begin
    SetLength(A, 2);
    A[1] := '0';
  end;
  for I := 0 to Length(A) - 1 do
  begin
    result := StrToInt(A[I], Part);
    if not result then
      break;
    result := (Part >= 0) and (Part <= $FFFF);
    if not result then
      break;
    result := StrToWord(A[I], Version[I]);
    if not result then
      break;
  end;
end;

function TestVersionString(const S: string): Boolean;
var
  Version: TVersionArray;
begin
  result := GetVersionArray(S, Version);
end;

// Should test version strings using TestVersionString before using this
// to compare them
function CompareVersionStrings(const V1, V2: string): Integer;
var
  Ver1, Ver2: TVersionArray;
  I: Integer;
begin
  result := 0;
  if not GetVersionArray(V1, Ver1) then
    exit;
  if not GetVersionArray(V2, Ver2) then
    exit;
  for I := 0 to 1 do
  begin
    if Ver1[I] > Ver2[I] then
    begin
      result := 1;
      exit;
    end
    else if Ver1[I] < Ver2[I] then
    begin
      result := -1;
      exit;
    end;
  end;
end;

function GetFileVersion(const FileName: string): string;
var
  VerInfoSize, Handle: DWORD;
  pBuffer: Pointer;
  pFileInfo: ^VS_FIXEDFILEINFO;
  Len: UINT;
begin
  result := '';
  VerInfoSize := GetFileVersionInfoSizeW(PChar(FileName),  // LPCWSTR lptstrFilename
    Handle);                                               // LPDWORD lpdwHandle
  if VerInfoSize > 0 then
  begin
    GetMem(pBuffer, VerInfoSize);
    if GetFileVersionInfoW(PChar(FileName),  // LPCWSTR lptstrFilename
      Handle,                                // DWORD   dwHandle
      VerInfoSize,                           // DWORD   dwLen
      pBuffer) then                          // LPVOID  lpData
    begin
      if VerQueryValueW(pBuffer,  // LPCVOID pBlock
        '\',                      // LPCWSTR lpSubBlock
        pFileInfo,                // LPVOID  *lplpBuffer
        Len) then                 // PUINT   puLen
      begin
        with pFileInfo^ do
        begin
          result := IntToStr(HiWord(dwFileVersionMS)) + '.' +
            IntToStr(LoWord(dwFileVersionMS)) + '.' +
            IntToStr(HiWord(dwFileVersionLS));
          // LoWord(dwFileVersionLS) intentionally omitted
        end;
      end;
    end;
    FreeMem(pBuffer);
  end;
end;

function GetProcessorArchitecture(): TProcessorArchitecture;
type
  TGetNativeSystemInfo = procedure(out lpSystemInfo: SYSTEM_INFO); stdcall;
var
  ModuleHandle: HANDLE;
  GetNativeSystemInfo: TGetNativeSystemInfo;
  SI: SYSTEM_INFO;
  Architecture: TProcessorArchitecture;
begin
  result := ProcessorArchitectureX86;
  ModuleHandle := LoadLibraryW('kernel32.dll');  // LPCWSTR lpLibFileName
  if ModuleHandle = 0 then
    exit;
  GetNativeSystemInfo := TGetNativeSystemInfo(GetProcAddress(ModuleHandle,  // HMODULE hModule
    'GetNativeSystemInfo'));                                                // LPCSTR  lpProcName
  if Assigned(GetNativeSystemInfo) then
  begin
    GetNativeSystemInfo(SI);
    case SI.wProcessorArchitecture of
      PROCESSOR_ARCHITECTURE_INTEL:   Architecture := ProcessorArchitectureX86;
      PROCESSOR_ARCHITECTURE_ARM:     Architecture := ProcessorArchitectureARM;
      PROCESSOR_ARCHITECTURE_IA64:    Architecture := ProcessorArchitectureIA64;
      PROCESSOR_ARCHITECTURE_AMD64:   Architecture := ProcessorArchitectureAMD64;
      PROCESSOR_ARCHITECTURE_ARM64:   Architecture := ProcessorArchitectureARM64;
      else
        Architecture := ProcessorArchitectureUnknown;
    end;
    result := TProcessorArchitecture(Architecture);
  end;
  FreeLibrary(ModuleHandle);  // HMODULE hLibModule
end;

// Uses RtlGetVersion rather than GetVersionEx to get the actual Windows
// version, because GetVersionEx lies about the version information starting
// with Windows 8.1/Server 2012 R2
function GetOVI(var OVI: RTL_OSVERSIONINFOEXW): DWORD;
type
  NTSYSAPI = DWORD;
  TRtlGetVersion = function(out lpVersionInformation: RTL_OSVERSIONINFOEXW): NTSYSAPI; stdcall;
var
  ModuleHandle: HANDLE;
  RtlGetVersion: TRtlGetVersion;
begin
  ModuleHandle := LoadLibraryW('ntdll.dll');  // LPCWSTR lpLibFileName
  if ModuleHandle = 0 then
  begin
    result := GetLastError();
    exit;
  end;
  RtlGetVersion := TRtlGetVersion(GetProcAddress(ModuleHandle,  // HMODULE hModule
    'RtlGetVersion'));                                          // LPCSTR  lpProcName
  if Assigned(RtlGetVersion) then
  begin
    OVI.dwOSVersionInfoSize := SizeOf(OVI);
    result := RtlGetVersion(OVI);
  end
  else
    result := ERROR_PROC_NOT_FOUND;
  FreeLibrary(ModuleHandle);  // HMODULE hLibModule
end;

function IsDomainMember(): Boolean;
type
  NET_API_STATUS = DWORD;
  TJoinStatus = (
    NetSetupUnknownStatus = 0,
    NetSetupUnjoined      = 1,
    NetSetupWorkgroupName = 2,
    NetSetupDomainName    = 3);
  TNetGetJoinInformation = function(lpServer: LPCWSTR;
    out lpNameBuffer: LPWSTR;
    out BufferType: TJoinStatus): NET_API_STATUS; stdcall;
  TNetApiBufferFree = function(Buffer: Pointer): NET_API_STATUS; stdcall;
var
  ModuleHandle: HANDLE;
  NetGetJoinInformation: TNetGetJoinInformation;
  NetApiBufferFree: TNetApiBufferFree;
  pNameBuffer: PChar;
  JoinStatus: TJoinStatus;
begin
  result := false;
  ModuleHandle := LoadLibraryW('netapi32.dll');  // LPCWSTR lpLibFileName
  if ModuleHandle = 0 then
    exit;
  NetGetJoinInformation := TNetGetJoinInformation(GetProcAddress(ModuleHandle,  // HMODULE hModule
    'NetGetJoinInformation'));                                                  // LPCSTR  lpProcName
  NetApiBufferFree := TNetApiBufferFree(GetProcAddress(ModuleHandle,  // HMODULE hModule
    'NetApiBufferFree'));                                             // LPCSTR  lpProcName
  if Assigned(NetGetJoinInformation) and Assigned(NetApiBufferFree) then
  begin
    if NetGetJoinInformation(nil,       // LPCWSTR               lpServer
      pNameBuffer,                      // LPWSTR                *lpNameBuffer
      JoinStatus) = ERROR_SUCCESS then  // PNETSETUP_JOIN_STATUS BufferType
    begin
      result := JoinStatus = NetSetupDomainName;
      NetApiBufferFree(pNameBuffer);  // _Frees_ptr_opt_ LPVOID Buffer
    end;
  end;
  FreeLibrary(ModuleHandle);  // HMODULE hLibModule
end;

function GetProdInfo(const OSMajor, OSMinor, SPMajor, SPMinor: DWORD): DWORD;
const
  PRODUCT_UNDEFINED = 0;
type
  TGetProductInfo = function(dwOSMajorVersion,
    dwOSMinorVersion,
    dwSpMajorVersion,
    dwSpMinorVersion: DWORD;
    out pdwReturnedProductType: DWORD): BOOL; stdcall;
var
  ModuleHandle: HANDLE;
  GetProductInfo: TGetProductInfo;
  ProdType: DWORD;
begin
  result := PRODUCT_UNDEFINED;
  ModuleHandle := LoadLibraryW('kernel32.dll');  // LPCWSTR lpLibFileName
  if ModuleHandle = 0 then
    exit;
  GetProductInfo := TGetProductInfo(GetProcAddress(ModuleHandle,  // HMODULE hModule
    'GetProductInfo'));                                           // LPCSTR  lpProcName
  if Assigned(GetProductInfo) then
  begin
    if GetProductInfo(OSMajor,  // DWORD  dwOSMajorVersion
      OSMinor,                  // DWORD  dwOSMinorVersion
      SPMajor,                  // DWORD  dwSpMajorVersion
      SPMinor,                  // DWORD  dwSpMinorVersion
      ProdType) then            // PDWORD pdwReturnedProductType
    begin
      result := ProdType;
    end;
  end;
  FreeLibrary(ModuleHandle);  // HMODULE hLibModule
end;

// Uses various means to get OS version data and other details
function GetWindowsOSInfo(var OSI: TWindowsOSInfo): DWORD;
const
  SUBKEY_NAME = 'SOFTWARE\Microsoft\Windows NT\CurrentVersion';
var
  OVI: RTL_OSVERSIONINFOEXW;
  UBR: DWORD;
  DisplayVersion, ReleaseID: string;
begin
  // Abort, OS too old...
  if not IsWindowsNewEnough() then
  begin
    result := ERROR_OLD_WIN_VERSION;
    exit;
  end;

  // Call RtlGetVersion to get build number and version
  result := GetOVI(OVI);
  if result <> STATUS_SUCCESS then
    exit;

  FillChar(OSI, SizeOf(OSI), 0);
  OSI.BuildNumber := OVI.dwBuildNumber;
  OSI.VersionNumber := DWORDToStr(OVI.dwMajorVersion) + '.' +
    DWORDToStr(OVI.dwMinorVersion);

  // Architecture
  OSI.Architecture := GetProcessorArchitecture();

  // Get update build revision
  if RegGetDWORDValue('',      // ComputerName
    HKEY_LOCAL_MACHINE,        // RootKey
    SUBKEY_NAME,               // SubKeyName
    'UBR',                     // ValueName
    UBR) = ERROR_SUCCESS then  // ValueData
  begin
    OSI.BuildRevision := UBR;
  end;

  // Get DisplayVersion
  if RegGetStringValue('',                // ComputerName
    HKEY_LOCAL_MACHINE,                   // RootKey
    SUBKEY_NAME,                          // SubKeyName
    'DisplayVersion',                     // ValueName
    DisplayVersion) = ERROR_SUCCESS then  // ValueData
  begin
    OSI.DisplayVersion := DisplayVersion;
  end;

  // Get ReleaseID
  if RegGetStringValue('',           // ComputerName
    HKEY_LOCAL_MACHINE,              // RootKey
    SUBKEY_NAME,                     // SubKeyName
    'ReleaseId',                     // ValueName
    ReleaseID) = ERROR_SUCCESS then  // ValueData
  begin
    OSI.ReleaseID := ReleaseID;
  end;

  // Domain controller?
  OSI.DomainController := OVI.wProductType = VER_NT_DOMAIN_CONTROLLER;

  // Are we joined to a domain?
  OSI.DomainMember := IsDomainMember();

  // If VER_SUITE_PERSONAL bit set in wSuiteMask, then home edition
  OSI.HomeEdition := (OVI.wSuiteMask and VER_SUITE_PERSONAL) <> 0;

  // If VER_SUITE_TERMINAL bit set and VER_SUITE_SINGLEUSERTS not set
  // in wSuiteMask, then RD server
  OSI.RDSServer := ((OVI.wSuiteMask and VER_SUITE_TERMINAL) <> 0) and
    ((OVI.wSuiteMask and VER_SUITE_SINGLEUSERTS) = 0);

  // Return value from GetProductInfo API
  OSI.ProductInfo := GetProdInfo(OVI.dwMajorVersion, OVI.dwMinorVersion,
    OVI.wServicePackMajor, OVI.wServicePackMinor);

  // Workstation or server? (DC is a server)
  case OVI.wProductType of
    VER_NT_WORKSTATION:       OSI.ProductType := ProductTypeWorkstation;
    VER_NT_DOMAIN_CONTROLLER: OSI.ProductType := ProductTypeServer;
    VER_NT_SERVER:            OSI.ProductType := ProductTypeServer;
  end;

  // Is current session Remote Desktop (RD)?
  OSI.RDSession := GetSystemMetrics(SM_REMOTESESSION) <> 0;
end;

begin
end.
