<#
  IsoBurnGuard.ps1
  User-mode watcher that intercepts "isoburn.exe" launches and
  reroutes them to BurnIsoAndFinalize.ps1 so media is always closed.

  Install:
    - Place this script and BurnIsoAndFinalize.ps1 together.
    - (Optional) create a per-user Startup shortcut that runs this script hidden.

  Behavior:
    - Polls every 300 ms for new "isoburn.exe" processes (no admin required).
    - Extracts ISO path and optional drive letter from the command line.
    - Terminates isoburn.exe and invokes BurnIsoAndFinalize.ps1 instead.
    - Logs to %LOCALAPPDATA%\IsoBurnGuard\guard.log
#>

[CmdletBinding()]
param(
  [string]$DefaultDrive = "D:",
  [int]$PollMs = 300
)

$ErrorActionPreference = "Stop"

# Resolve companion burner script path
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$burner = Join-Path $scriptDir "BurnIsoAndFinalize.ps1"
if (-not (Test-Path $burner)) { throw "BurnIsoAndFinalize.ps1 not found next to IsoBurnGuard.ps1" }

# Log setup
$logDir = Join-Path $env:LOCALAPPDATA "IsoBurnGuard"
$null = New-Item -Path $logDir -ItemType Directory -Force
$log = Join-Path $logDir "guard.log"
function Log([string]$msg) {
  $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
  "$timestamp $msg" | Out-File -FilePath $log -Append -Encoding ascii
}

# Track seen PIDs to avoid repeats
$seen = New-Object System.Collections.Generic.HashSet[int]

Log "IsoBurnGuard started. Watching for isoburn.exe"

while ($true) {
  try {
    $procs = Get-Process -Name isoburn -ErrorAction SilentlyContinue

    foreach ($p in $procs) {
      if ($seen.Contains($p.Id)) { continue }
      [void]$seen.Add($p.Id)

      # Try to capture command line
      $cmd = $null
      try {
        $wmi = Get-CimInstance Win32_Process -Filter "ProcessId=$($p.Id)"
        $cmd = $wmi.CommandLine
      }
      catch {
        $cmd = $null
      }

      $cmdForLog = if ($null -eq $cmd) { "<none>" } else { $cmd }
      Log ("Detected isoburn PID={0} CMD={1}" -f $p.Id, $cmdForLog)

      # Parse arguments: isoburn.exe [/Q] [<drive>:] <isoPath>
      $drive = $null
      $iso = $null

      if ($cmd) {
        $nullRef = $null
        $tokens = [System.Management.Automation.PSParser]::Tokenize($cmd, [ref]$nullRef) |
        Where-Object { $_.Type -in 'String', 'CommandArgument' } |
        Select-Object -ExpandProperty Content

        foreach ($t in $tokens) {
          # normalize quotes
          $arg = $t.Trim('"')

          # drive letter param (e.g., D:)
          if (-not $drive -and $arg -match '^[A-Za-z]:$') {
            $drive = $arg
            continue
          }

          # probable ISO/IMG file path
          if (-not $iso -and (Test-Path -LiteralPath $arg)) {
            $ext = [System.IO.Path]::GetExtension($arg)
            if ($ext -and ($ext.Equals(".iso", [System.StringComparison]::OrdinalIgnoreCase) -or
                $ext.Equals(".img", [System.StringComparison]::OrdinalIgnoreCase))) {
              $iso = $arg
            }
          }
        }
      }

      if (-not $iso) {
        Log "Could not determine ISO path; leaving isoburn running for this instance."
        continue
      }

      if (-not $drive) { $drive = $DefaultDrive }

      # Terminate isoburn and call the finalized burner
      try {
        Stop-Process -Id $p.Id -Force
        Log ("Stopped isoburn PID={0}" -f $p.Id)
      }
      catch {
        Log ("Failed to stop isoburn PID={0}: {1}" -f $p.Id, $_.Exception.Message)
        continue
      }

      try {
        Log ("Rerouting to BurnIsoAndFinalize: ISO={0} Drive={1}" -f $iso, $drive)
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $burner -IsoPath $iso -DriveLetter $drive
      }
      catch {
        Log ("BurnIsoAndFinalize failed: {0}" -f $_.Exception.Message)
      }
    }
  }
  catch {
    Log ("Watcher loop error: {0}" -f $_.Exception.Message)
  }

  Start-Sleep -Milliseconds $PollMs
}