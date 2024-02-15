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

program osinfo;

{$MODE OBJFPC}
{$MODESWITCH UNICODESTRINGS}
{$R *.res}

// wargcv and wgetopts: https://github.com/Bill-Stewart/wargcv
uses
  windows,
  wargcv,
  wgetopts,
  TextUtil,
  WindowsMessages,
  WindowsOSInfo;

const
  PROGRAM_NAME = 'osinfo';
  PROGRAM_COPYRIGHT = 'Copyright (C) 2024 by Bill Stewart';

type
  TParamSet = (
    ParamSetArchitecture,
    ParamSetBuildNumber,
    ParamSetBuildRevision,
    ParamSetDisplayVersion,
    ParamSetDomainController,
    ParamSetDomainMember,
    ParamSetHelp,
    ParamSetHomeEdition,
    ParamSetProductInfo,
    ParamSetProductType,
    ParamSetReleaseID,
    ParamSetRDSession,
    ParamSetRDSServer,
    ParamSetVersionNumber);
  TCommandLine = object
    ParamSet: set of TParamSet;
    Error: DWORD;
    Help: Boolean;
    Quiet: Boolean;
    Architecture: TProcessorArchitecture;
    BuildNumber: DWORD;
    BuildRevision: DWORD;
    DisplayVersion: string;
    ProductInfo: DWORD;
    ProductType: TProductType;
    ReleaseID: string;
    VersionNumber: string;
    ExactMatch: Boolean;
    DomainController, DomainMember, HomeEdition, RDSession, RDSServer: Boolean;
    function GetBoolArg(const Arg: string; out Param: Boolean): DWORD;
    procedure Parse();
  end;

procedure Usage();
begin
  WriteLn(PROGRAM_NAME, ' ', GetFileVersion(ParamStr(0)), ' - ', PROGRAM_COPYRIGHT);
  WriteLn('This is free software and comes with ABSOLUTELY NO WARRANTY.');
  WriteLn();
  WriteLn('SYNOPSIS');
  WriteLn();
  WriteLn('Checks for, or outputs, information regarding the current system.');
  WriteLn();
  WriteLn('USAGE');
  WriteLn();
  WriteLn(PROGRAM_NAME, ' [option [...] [--exact] [--quiet]]');
  WriteLn();
  WriteLn('Option             | Argument                        | Data Type');
  WriteLn('------------------ | ------------------------------- | ---------');
  WriteLn('--architecture     | x86, ARM, IA64, AMD64, or ARM64 | String');
  WriteLn('--buildnumber      | Build number (e.g., 20348)      | Numeric');
  WriteLn('--buildrevision    | Build revision (e.g., 3155)     | Numeric');
  WriteLn('--displayversion   | Display version (e.g., 22H2)    | String');
  WriteLn('--domaincontroller | true or false                   | Boolean');
  WriteLn('--domainmember     | true or false                   | Boolean');
  WriteLn('--homeedition      | true or false                   | Boolean');
  WriteLn('--productinfo      | Product info value (e.g., 48)   | Number');
  WriteLn('--producttype      | Workstation or Server           | String');
  WriteLn('--releaseid        | Release id (e.g., 2009)         | String');
  WriteLn('--rdsession        | true or false                   | Boolean');
  WriteLn('--rdsserver        | true or false                   | Boolean');
  WriteLn('--version          | Version (e.g., 6.3 or 10)       | String');
  WriteLn();
  WriteLn('COMMENTS');
  WriteLn();
  WriteLn('* Omit all options to output information about current system');
  WriteLn('* Option names are case-sensitive; option arguments are not');
  WriteLn('* --buildnumber, --buildrevision, and --version will match if the current');
  WriteLn('  system is at least the specified value; the --exact option indicates that');
  WriteLn('  these should be exact matches instead');
  WriteLn('* The --quiet option suppresses the message regarding match/non-match');
  WriteLn();
  WriteLn('EXIT CODES');
  WriteLn();
  WriteLn('* 0 - One or more specified options do not match current system');
  WriteLn('* 1 - All specified options match current system');
  WriteLn('* Any other exit code indicates an error');
  WriteLn();
  WriteLn('EXAMPLE');
  WriteLn();
  WriteLn(PROGRAM_NAME, ' --buildnumber 20348 --domaincontroller true');
  WriteLn('* Returns 1 if current system is Server 2022 or newer DC, or 0 if not');
end;

function TCommandLine.GetBoolArg(const Arg: string; out Param: Boolean): DWORD;
begin
  result := ERROR_SUCCESS;
  if SameText(Arg, 'true') then
    Param := true
  else if SameText(arg, 'false') then
    Param := false
  else
    result := ERROR_INVALID_PARAMETER;
end;

procedure TCommandLine.Parse();
var
  Opts: array[1..17] of TOption;
  Opt: Char;
  I: Integer;
begin
  with Opts[1] do
  begin
    Name := 'architecture';
    Has_arg := Required_Argument;
    Flag := nil;
    Value := 'a';
  end;
  with Opts[2] do
  begin
    Name := 'buildnumber';
    Has_arg := Required_Argument;
    Flag := nil;
    Value := 'b';
  end;
  with Opts[3] do
  begin
    Name := 'buildrevision';
    Has_arg := Required_Argument;
    Flag := nil;
    Value := #0;
  end;
  with Opts[4] do
  begin
    Name := 'displayversion';
    Has_arg := Required_Argument;
    Flag := nil;
    Value := 'd';
  end;
  with Opts[5] do
  begin
    Name := 'domaincontroller';
    Has_arg := Required_Argument;
    Flag := nil;
    Value := #0;
  end;
  with Opts[6] do
  begin
    Name := 'domainmember';
    Has_arg := Required_Argument;
    Flag := nil;
    Value := #0;
  end;
  with Opts[7] do
  begin
    Name := 'exact';
    Has_arg := No_Argument;
    Flag := nil;
    value := #0;
  end;
  with Opts[8] do
  begin
    Name := 'help';
    Has_arg := No_Argument;
    Flag := nil;
    value := 'h';
  end;
  with Opts[9] do
  begin
    Name := 'homeedition';
    Has_arg := Required_Argument;
    Flag := nil;
    Value := #0;
  end;
  with Opts[10] do
  begin
    Name := 'productinfo';
    Has_arg := Required_Argument;
    Flag := nil;
    Value := #0;
  end;
  with Opts[11] do
  begin
    Name := 'producttype';
    Has_arg := Required_Argument;
    Flag := nil;
    Value := 'p';
  end;
  with Opts[12] do
  begin
    Name := 'quiet';
    Has_arg := No_Argument;
    Flag := nil;
    Value := 'q';
  end;
  with Opts[13] do
  begin
    Name := 'releaseid';
    Has_arg := Required_Argument;
    Flag := nil;
    Value := #0;
  end;
  with Opts[14] do
  begin
    Name := 'rdsession';
    Has_arg := Required_Argument;
    Flag := nil;
    Value := #0;
  end;
  with Opts[15] do
  begin
    Name := 'rdsserver';
    Has_arg := Required_Argument;
    Flag := nil;
    Value := #0;
  end;
  with Opts[16] do
  begin
    Name := 'version';
    Has_arg := Required_Argument;
    Flag := nil;
    Value := 'v';
  end;
  with Opts[17] do
  begin
    Name := '';
    Has_arg := No_Argument;
    Flag := nil;
    Value := #0;
  end;
  ParamSet := [];
  Error := ERROR_SUCCESS;
  Help := false;
  Quiet := false;
  ExactMatch := false;
  OptErr := false;
  repeat
    Opt := GetLongOpts('a:b:hp:qv:', @Opts[1], I);
    case Opt of
      'a':  // --architecture
      begin
        OptArg := LowercaseString(OptArg);
        case OptArg of
          'x86':     Architecture := ProcessorArchitectureX86;
          'arm':     Architecture := ProcessorArchitectureARM;
          'ia64':    Architecture := ProcessorArchitectureIA64;
          'amd64':   Architecture := ProcessorArchitectureAMD64;
          'arm64':   Architecture := ProcessorArchitectureARM64;
          'unknown': Architecture := ProcessorArchitectureUnknown;
          else
            Error := ERROR_INVALID_PARAMETER;
        end;
        if Error = ERROR_SUCCESS then
          Include(ParamSet, ParamSetArchitecture);
      end;
      'b':  // --buildnumber
      begin
        if StrToDWORD(OptArg, BuildNumber) then
          Include(ParamSet, ParamSetBuildNumber)
        else
          Error := ERROR_INVALID_PARAMETER;
      end;
      'h':  // --help
      begin
        Include(ParamSet, ParamSetHelp);
        break;
      end;
      'p':  // --producttype
      begin
        OptArg := LowercaseString(OptArg);
        case OptArg of
          'server':      ProductType := ProductTypeServer;
          'workstation': ProductType := ProductTypeWorkstation;
          else
            Error := ERROR_INVALID_PARAMETER;
        end;
        if Error = ERROR_SUCCESS then
          Include(ParamSet, ParamSetProductType);
      end;
      'q':  // --quiet
      begin
        Quiet := true;
      end;
      'v':  // --version
      begin
        if TestVersionString(OptArg) then
        begin
          VersionNumber := OptArg;
          Include(ParamSet, ParamSetVersionNumber);
        end
        else
          Error := ERROR_INVALID_PARAMETER;
      end;
      #0:
      case Opts[I].Name of
        'buildrevision':
        begin
          if StrToDWORD(OptArg, BuildRevision) then
            Include(ParamSet, ParamSetBuildRevision)
          else
            Error := ERROR_INVALID_PARAMETER;
        end;
        'displayversion':
        begin
          DisplayVersion := OptArg;
          Include(ParamSet, ParamSetDisplayVersion);
        end;
        'domaincontroller':
        begin
          Error := GetBoolArg(OptArg, DomainController);
          if Error = ERROR_SUCCESS then
            Include(ParamSet, ParamSetDomainController);
        end;
        'domainmember':
        begin
          Error := GetBoolArg(OptArg, DomainMember);
          if Error = ERROR_SUCCESS then
            Include(ParamSet, ParamSetDomainMember);
        end;
        'exact':
        begin
          ExactMatch := true;
        end;
        'homeedition':
        begin
          Error := GetBoolArg(OptArg, HomeEdition);
          if Error = ERROR_SUCCESS then
            Include(ParamSet, ParamSetHomeEdition);
        end;
        'productinfo':
        begin
          if StrToDWORD(OptArg, ProductInfo) then
            Include(ParamSet, ParamSetProductInfo)
          else
            Error := ERROR_INVALID_PARAMETER;
        end;
        'releaseid':
        begin
          ReleaseID := OptArg;
          Include(ParamSet, ParamSetReleaseID);
        end;
        'rdsession':
        begin
          Error := GetBoolArg(OptArg, RDSession);
          if Error = ERROR_SUCCESS then
            Include(ParamSet, ParamSetRDSession);
        end;
        'rdsserver':
        begin
          Error := GetBoolArg(OptArg, RDSServer);
          if Error = ERROR_SUCCESS then
            Include(ParamSet, ParamSetRDSServer);
        end;
      end;
      '?':
      begin
        Error := ERROR_INVALID_PARAMETER;
      end;
    end;
    if ERROR <> ERROR_SUCCESS then
      break;
  until Opt = EndOfOptions;
end;

function BoolToStr(const B: Boolean): string;
begin
  if B then
    result := 'true'
  else
    result := 'false';
end;

procedure OutputWindowsOSInfo(var OSI: TWindowsOSInfo);
var
  S: string;
begin
  with OSI do
  begin
    case Architecture of
      ProcessorArchitectureX86:   S := 'x86';
      ProcessorArchitectureARM:   S := 'ARM';
      ProcessorArchitectureIA64:  S := 'IA64';
      ProcessorArchitectureAMD64: S := 'AMD64';
      ProcessorArchitectureARM64: S := 'ARM64';
      else
        S := 'Unknown';
    end;
    WriteLn('architecture: '     + S);
    WriteLn('buildnumber: '      + DWORDToStr(BuildNumber));
    WriteLn('buildrevision: '    + DWORDToStr(BuildRevision));
    WriteLn('displayversion: '   + DisplayVersion);
    WriteLn('domaincontroller: ' + BoolToStr(DomainController));
    WriteLn('domainmember: '     + BoolToStr(DomainMember));
    WriteLn('homeedition: '      + BoolToStr(HomeEdition));
    WriteLn('productinfo: '      + DWORDToStr(ProductInfo)
      + ' (0x' + HexStr(ProductInfo, 8), ')');
    case ProductType of
      ProductTypeServer:      S := 'Server';
      ProductTypeWorkstation: S := 'Workstation';
      else
        S := 'Unknown';
    end;
    WriteLn('producttype: ' + S);
    WriteLn('releaseid: '   + ReleaseID);
    WriteLn('rdsession: '   + BoolToStr(RDSession));
    WriteLn('rdsserver: '   + BoolToStr(RDSServer));
    WriteLn('version: '     + VersionNumber);
  end;
end;

var
  CmdLine: TCommandLine;
  RC: DWORD;
  OSI: TWindowsOSInfo;
  MatchingParams: set of TParamSet;

begin
  CmdLine.Parse();
  if (ParamStr(1) = '/?') or (ParamSetHelp in CmdLine.ParamSet) then
  begin
    Usage();
    exit;
  end;

  RC := CmdLine.Error;
  if RC <> ERROR_SUCCESS then
  begin
    WriteLn(GetWindowsMessage(RC, true));
    ExitCode := Integer(RC);
    exit;
  end;

  RC := GetWindowsOSInfo(OSI);
  if RC <> ERROR_SUCCESS then
  begin
    WriteLn(GetWindowsMessage(RC), true);
    ExitCode := Integer(RC);
    exit;
  end;

  if CmdLine.ParamSet = [] then
  begin
    OutputWindowsOSInfo(OSI);
    exit;
  end;

  MatchingParams := [];

  // --architecture
  if ParamSetArchitecture in CmdLine.ParamSet then
  begin
    if OSI.Architecture = CmdLine.Architecture then
      Include(MatchingParams, ParamSetArchitecture);
  end;

  // --buildnumber [--exact]
  if ParamSetBuildNumber in CmdLine.ParamSet then
  begin
    if CmdLine.ExactMatch then
    begin
      if OSI.BuildNumber = CmdLine.BuildNumber then
        Include(MatchingParams, ParamSetBuildNumber);
    end
    else
    begin
      if OSI.BuildNumber >= CmdLine.BuildNumber then
        Include(MatchingParams, ParamSetBuildNumber);
    end;
  end;

  // --buildrevision [--exact]
  if ParamSetBuildRevision in CmdLine.ParamSet then
  begin
    if CmdLine.ExactMatch then
    begin
      if OSI.BuildRevision = CmdLine.BuildRevision then
        Include(MatchingParams, ParamSetBuildRevision);
    end
    else
    begin
      if OSI.BuildRevision >= CmdLine.BuildRevision then
        Include(MatchingParams, ParamSetBuildRevision);
    end;
  end;

  // --displayversion
  if ParamSetDisplayVersion in CmdLine.ParamSet then
  begin
    if SameText(CmdLine.DisplayVersion, OSI.DisplayVersion) then
      Include(MatchingParams, ParamSetDisplayVersion);
  end;

  // --domaincontroller
  if ParamSetDomainController in CmdLine.ParamSet then
  begin
    if CmdLine.DomainController = OSI.DomainController then
      Include(MatchingParams, ParamSetDomainController);
  end;

  // --domainmember
  if ParamSetDomainMember in CmdLine.ParamSet then
  begin
    if CmdLine.DomainMember = OSI.DomainMember then
      Include(MatchingParams, ParamSetDomainMember);
  end;

  // --homeedition
  if ParamSetHomeEdition in CmdLine.ParamSet then
  begin
    if CmdLine.HomeEdition = OSI.HomeEdition then
      Include(MatchingParams, ParamSetHomeEdition);
  end;

  // --productinfo
  if ParamSetProductInfo in CmdLine.ParamSet then
  begin
    if CmdLine.ProductInfo = OSI.ProductInfo then
      Include(MatchingParams, ParamSetProductInfo);
  end;

  // --producttype
  if ParamSetProductType in CmdLine.ParamSet then
  begin
    if CmdLine.ProductType = OSI.ProductType then
      Include(MatchingParams, ParamSetProductType);
  end;

  // --releaseid
  if ParamSetReleaseID in CmdLine.ParamSet then
  begin
    if SameText(CmdLine.ReleaseID, OSI.ReleaseID) then
      Include(MatchingParams, ParamSetReleaseID);
  end;

  // --rdsession
  if ParamSetRDSession in CmdLine.ParamSet then
  begin
    if CmdLine.RDSession = OSI.RDSession then
      Include(MatchingParams, ParamSetRDSession);
  end;

  // --rdsserver
  if ParamSetRDSServer in CmdLine.ParamSet then
  begin
    if CmdLine.RDSServer = OSI.RDSServer then
      Include(MatchingParams, ParamSetRDSServer);
  end;

  // --version [--exact]
  if ParamSetVersionNumber in CmdLine.ParamSet then
  begin
    if CmdLine.ExactMatch then
    begin
      if CompareVersionStrings(OSI.VersionNumber, CmdLine.VersionNumber) = 0 then
        Include(MatchingParams, ParamSetVersionNumber);
    end
    else
    begin
      if CompareVersionStrings(OSI.VersionNumber, CmdLine.VersionNumber) >= 0 then
        Include(MatchingParams, ParamSetVersionNumber);
    end;
  end;

  if CmdLine.ParamSet = MatchingParams then
  begin
    RC := 1;
    if not CmdLine.Quiet then
      WriteLn('All options match current system.');
  end
  else
  begin
    if not CmdLine.Quiet then
      WriteLn('One or more options do not match current system.');
  end;

  ExitCode := Integer(RC);
end.
