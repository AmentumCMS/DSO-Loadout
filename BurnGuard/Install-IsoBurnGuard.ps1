<#
  Install-IsoBurnGuard.ps1
  Creates a per-user Startup shortcut for IsoBurnGuard.ps1.
  No elevation required.

  After running, the guard will auto-start at next sign-in.
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$guard = Join-Path $scriptDir "IsoBurnGuard.ps1"
if (-not (Test-Path $guard)) { throw "IsoBurnGuard.ps1 not found next to this installer." }

$startup = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Startup"
$lnk = Join-Path $startup "IsoBurnGuard.lnk"

$ws = New-Object -ComObject WScript.Shell
$sc = $ws.CreateShortcut($lnk)
$sc.TargetPath = "powershell.exe"
$sc.Arguments  = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$guard`""
$sc.WorkingDirectory = $scriptDir
$sc.IconLocation = "$env:SystemRoot\System32\shell32.dll,167"
$sc.Save()

Write-Host "Installed Startup shortcut: $lnk"