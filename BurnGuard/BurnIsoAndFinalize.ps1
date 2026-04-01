<#
  BurnIsoAndFinalize.ps1
  Burns an ISO to the specified optical drive and CLOSES THE MEDIA
  (ForceMediaToBeClosed = TRUE), guaranteeing a non-appendable disc.

  Usage:
    .\BurnIsoAndFinalize.ps1 -IsoPath "C:\path\image.iso" -DriveLetter "D:"

  Notes:
    - Uses only native COM (IMAPI2) and SHCreateStreamOnFile.
    - The ISO stream is sector-aligned (2048 bytes), suitable for Write().
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)]
  [ValidateScript({ Test-Path $_ })]
  [string]$IsoPath,

  [Parameter(Mandatory=$true)]
  [ValidatePattern('^[A-Za-z]:$')]
  [string]$DriveLetter
)

# 1) SHCreateStreamOnFile (IStream over the ISO)
Add-Type -Language CSharp -Namespace Win32 -Name Shlwapi -MemberDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Runtime.InteropServices.ComTypes;
public static class Shlwapi {
  [DllImport("shlwapi.dll", CharSet=CharSet.Unicode, PreserveSig=true)]
  public static extern int SHCreateStreamOnFile(string pszFile, uint grfMode, out IStream ppstm);
}
"@
$STGM_READ = 0x00000000
$STGM_SHARE_DENY_WRITE = 0x00000020

function Get-RecorderForDrive([string]$DriveLetter) {
  $target = $DriveLetter.ToUpper()
  $dm = New-Object -ComObject IMAPI2.MsftDiscMaster2
  foreach ($id in $dm) {
    $rec = New-Object -ComObject IMAPI2.MsftDiscRecorder2
    try {
      $rec.InitializeDiscRecorder($id)
      $paths = @($rec.VolumePathNames)
      if ($paths -and ($paths | Where-Object { $_.ToUpper().StartsWith($target) })) { return $rec }
    } catch {
      if ($rec) { [Runtime.InteropServices.Marshal]::ReleaseComObject($rec) | Out-Null }
    }
    [Runtime.InteropServices.Marshal]::ReleaseComObject($rec) | Out-Null
  }
  if (@($dm).Count -eq 1) {
    $rec = New-Object -ComObject IMAPI2.MsftDiscRecorder2
    $rec.InitializeDiscRecorder(@($dm)[0])
    return $rec
  }
  throw "Recorder not found for $DriveLetter"
}

# 2) Resolve recorder and ensure media is present
$rec = Get-RecorderForDrive -DriveLetter $DriveLetter
$fmtProbe = New-Object -ComObject IMAPI2.MsftDiscFormat2Data
$fmtProbe.Recorder = $rec
if ($fmtProbe.CurrentMediaStatus -band 0x2000) { throw "Media or drive appears write-protected." }

# 3) Open ISO as IStream
$isoStream = $null
$hr = [Win32.Shlwapi]::SHCreateStreamOnFile($IsoPath, ($STGM_READ -bor $STGM_SHARE_DENY_WRITE), [ref]$isoStream)
if ($hr -ne 0 -or -not $isoStream) { throw ("SHCreateStreamOnFile failed: 0x{0:X8}" -f $hr) }

# 4) Write with ForceMediaToBeClosed = TRUE (media gets closed at end of write)
$fmt = New-Object -ComObject IMAPI2.MsftDiscFormat2Data
$fmt.Recorder = $rec
$fmt.ClientName = "BurnIsoAndFinalize"
$fmt.ForceMediaToBeClosed = $true

Write-Host ("[Burn] Writing {0} to {1} and finalizing media..." -f (Split-Path $IsoPath -Leaf), $DriveLetter) -ForegroundColor Yellow
$fmt.Write($isoStream)

# 5) Eject and print final state
$rec.EjectMedia()
Start-Sleep -Seconds 2
$rec2 = Get-RecorderForDrive -DriveLetter $DriveLetter
$fmt2 = New-Object -ComObject IMAPI2.MsftDiscFormat2Data
$fmt2.Recorder = $rec2
$state = $fmt2.CurrentMediaStatus
"Finalized: {0}" -f ( ($state -band 0x4000) -ne 0 )
"Appendable: {0}" -f ( ($state -band 0x0004) -ne 0 )