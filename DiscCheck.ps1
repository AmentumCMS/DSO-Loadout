# Probe media details (no writing)
param(
  [Parameter(Mandatory=$false, Position=0)]
  [ValidatePattern('^[A-Za-z]:$')]
  [string]$DriveLetter = "D:"
)

# Resolve recorder by matching the drive letter to VolumePathNames
$dm  = New-Object -ComObject IMAPI2.MsftDiscMaster2
$rec = $null
foreach($id in $dm){ $r=New-Object -ComObject IMAPI2.MsftDiscRecorder2
  $r.InitializeDiscRecorder($id)
  if(@($r.VolumePathNames) -match ("^" + [regex]::Escape($DriveLetter) + ".*$")){$rec=$r;break}
  [Runtime.InteropServices.Marshal]::ReleaseComObject($r)|Out-Null
}
if(-not $rec){ throw "Recorder not found for $DriveLetter" }

$fmt = New-Object -ComObject IMAPI2.MsftDiscFormat2Data
$fmt.Recorder = $rec

# Show state bits and physical media type
$state = $fmt.CurrentMediaStatus
$phys  = $fmt.CurrentPhysicalMediaType
"CurrentMediaStatus (hex): 0x{0:X}" -f $state
"PhysicalMediaType      : {0}" -f $phys
# Flags of interest per IMAPI_FORMAT2_DATA_MEDIA_STATE
@(
  @{N='APPENDABLE';V=0x0004},
  @{N='FINAL_SESSION';V=0x0008},
  @{N='WRITE_PROTECTED';V=0x2000},
  @{N='FINALIZED';V=0x4000}
) | ForEach-Object {
  "{0,-15}: {1}" -f $_.N, ( ($state -band $_.V) -ne 0 )
}