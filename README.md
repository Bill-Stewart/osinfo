# osinfo

## SYNOPSIS

**osinfo** is a Windows console (text-based, command-line) program for checking various aspects of the current operating system (such as version, CPU architecture, and more). This can be useful in system scripts to target actions based on specified criteria.

**osinfo** requires Windows Vista/Server 2008 or newer.

## AUTHOR

Bill Stewart - bstewart at iname dot com

## LICENSE

**osinfo** is covered by the GNU Public License (GPL). See the file `LICENSE` for details.

## USAGE

`osinfo` [_option_ [...] [`--exact`] [`--quiet`]]

Option               | Argument                                  | Data Type
-------------------- | ----------------------------------------- | ---------
`--architecture`     | `x86`, `ARM`, `IA64`, `AMD64`, or `ARM64` | String
`--buildnumber`      | Build number (e.g., 20348)                | Numeric
`--buildrevision`    | Build revision (e.g., 3155)               | Numeric
`--displayversion`   | Display version (e.g., 22H2)              | String
`--domaincontroller` | `true` or `false`                         | Boolean
`--domainmember`     | `true` or `false`                         | Boolean
`--homeedition`      | `true` or `false`                         | Boolean
`--productinfo`      | Product info value (e.g., 48)             | Number
`--producttype`      | `Workstation` or `Server`                 | String
`--releaseid`        | Release id (e.g., 2009)                   | String
`--rdsession`        | `true` or `false`                         | Boolean
`--rdsserver`        | `true` or `false`                         | Boolean
`--version`          | Version (e.g., 6.3 or 10)                 | String

Please note the following:

* Omit all options to output information about current system

* Option names are case-sensitive; option arguments are not

* `--buildnumber`, `--buildrevision`, and `--version` will match if the current system is at least the specified value; the `--exact` option indicates that these should be exact matches instead

* The `--quiet` option suppresses the message regarding match/non-match

## USAGE NOTES

Specify one or more options on the command line, and **osinfo** will check whether the current system matches the specified options. If all options match, **osinfo** will return an exit code of 1; otherwise, if one or more of the options do not match, it will return an exit code of 0 (see **EXIT CODES**, below).

The `--exact` option applies to the `--buildnumber`, `--buildrevision`, and `--version` options. If you specify `--exact` anywhere on the command line, the values for any of these three options must match exactly. Without `--exact`, then the value for these three options will match if the current system is the specified value or greater. Take care not to specify a zero value for any of these three options without also specifying `--exact`, because a zero value for any of these three options without `--exact` always matches. Examples:

* `--buildnumber 22621` matches if the current system is build 22621 or greater

* `--version 6.2 --exact` matches only if the current system is exactly version 6.2

* `--buildrevision 0` without `--exact` always matches, because the current system's build revision will always be greater than or equal to zero

## OPTION NOTES

This section describes the various means by which **osinfo** retrieves information about the current system.

* The CPU architecture (`--architecture`) is retrieved using the [**GetNativeSystemInformation**](https://learn.microsoft.com/en-us/windows/win32/api/sysinfoapi/nf-sysinfoapi-getnativesysteminfo) Windows API function.

* The following options' details are retrieved using the [**RtlGetVersion**](https://learn.microsoft.com/en-us/windows-hardware/drivers/ddi/wdm/nf-wdm-rtlgetversion) Windows API function:

  * `--buildnumber`
  * `--domaincontroller`
  * `--homeedition`
  * `--producttype`
  * `--rdsserver`
  * `--version`

* The build revision (`--buildrevision`), display version (`--displayversion`) and release ID (`--releaseid`) are obtained from the registry:

   Root key: **HKEY\_LOCAL\_MACHINE**

   Subkey: **SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion**

     | Item            | Value Name
     | --------------- | ------------------
     | Build Revision  | **UBR**
     | Display Version | **DisplayVersion**
     | Release ID      | **ReleaseId**

* Domain membership (`--domainmember`) detection is determined using the [**NetGetJoinInformation**](https://learn.microsoft.com/en-us/windows/win32/api/lmjoin/nf-lmjoin-netgetjoininformation) Windows API function.

* The product info (`--productinfo`) value is retrieved using the [**GetProductInfo**](https://learn.microsoft.com/en-us/windows/win32/api/sysinfoapi/nf-sysinfoapi-getproductinfo) Windows API function.

   As of this writing, the product info value can be one of 101 possible values. Please see the Microsoft documentation page for the [**GetProductInfo**](https://learn.microsoft.com/en-us/windows/win32/api/sysinfoapi/nf-sysinfoapi-getproductinfo) API function for a list of possible values and the meaning of each.

* Remote Desktop (RD) session detection (`--rdsession`) is determined using the [**GetSystemMetrics**](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-getsystemmetrics) Windows API function.

## EXIT CODES

The program's exit code will be 1 if all specified options match the current system, or 0 if one or more options do not match the current system.

In PowerShell, the exit code is available in the `$LASTEXITCODE` variable. In cmd.exe, the exit code is available in the `ERRORLEVEL` dynamic environment variable (i.e., `%ERRORLEVEL%`).

The exit code will be 1150 (ERROR\_OLD\_WIN\_VERSION) if the operating system is older than Windows Vista/Server 2008.

## WINDOWS RELEASES

The following table lists Windows releases with starting build numbers prior to Windows 10/Server 2016:

Name                       | Version     | Build Number
-------------------------- | ----------- | ------------
Windows Vista/Server 2008  | 6.0         | 6000-6003
Windows 7/Server 2008 R2   | 6.1         | 7600-7601
Windows 8/Server 2012      | 6.2         | 9200
Windows 8.1/Server 2012 R2 | 6.3         | 9600

Notes regarding the above table:

* In Windows Vista/Sever 2008, the original build number was 6000 but increased with up to three service packs (6001 = service pack 1, 6002 = service pack 2, etc.)

* In Windows 7/Server 2008 R2, the original build number was 7600 but changed to 7601 with service pack 1.

Starting with Windows 10 and Server 2016, the version number changed to 10.0 and the build number reflects different revisions of the operating system. There are numerous resources available on the Internet to determine the values you can use to check for specific Windows OS releases.

## EXAMPLES

1. Check whether the current system is Windows 11 (or later) Home Edition:

       osinfo --version 10 --buildnumber 22000 --homeedition true

2. Check whether the current system is Windows Server 2012 R2:

       osinfo --version 6.3 --producttype Server

3. Check whether the current system is Windows 10 20H2:

       osinfo --version 10 --buildnumber 19042 --displayversion 20H2 --exact

4. Check whether the current system is a Remote Desktop Services (RDS) server:

       osinfo --rdsserver true

5. Example batch (shell script) logon script code fragment to end script if running on a DC:

       osinfo --domaincontroller true
       if %ERRORLEVEL% EQU 1 goto :EOF
