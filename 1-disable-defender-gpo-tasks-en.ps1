<#
.SYNOPSIS
    Disable Windows Defender "permanently" (IT-Connect method) - PART 1/2.

.DESCRIPTION
    Reproduces in PowerShell the following steps:
      1. Checks Tamper Protection status (must be disabled manually first).
      2. Applies the registry equivalent of the GPO "Turn off Microsoft Defender Antivirus"
         and "Turn off real-time protection".
      3. Disables the 4 Windows Defender scheduled tasks.

    Run in an ELEVATED PowerShell session, in normal boot mode.
    Intended for an isolated test VM only (snapshot before running).

.NOTES
    This method is documented as unstable: Tamper Protection can be re-enabled
    after a Windows update, which undoes these settings. Re-check after every
    major update, or restore a dedicated snapshot.
#>

#Requires -RunAsAdministrator

Write-Host "=== Step 1: checking Tamper Protection ===" -ForegroundColor Cyan
try {
    $status = Get-MpComputerStatus -ErrorAction Stop
    if ($status.IsTamperProtected) {
        Write-Warning "Tamper Protection is ENABLED. The following steps will be silently ignored by Windows until it is disabled manually."
        Write-Warning "Go to Windows Security > Virus & threat protection > Manage settings > Tamper Protection > Off."
        $continue = Read-Host "Continue anyway? (y/n)"
        if ($continue -ne "y") { exit }
    }
    else {
        Write-Host "Tamper Protection appears to be already disabled. OK." -ForegroundColor Green
    }
}
catch {
    Write-Warning "Unable to read Get-MpComputerStatus (Defender may already be partially disabled). Continuing."
}

Write-Host "`n=== Step 2: GPO registry equivalent ===" -ForegroundColor Cyan

$gpoPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"
$rtpPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection"

New-Item -Path $gpoPath -Force | Out-Null
New-Item -Path $rtpPath -Force | Out-Null

# Equivalent of "Turn off Microsoft Defender Antivirus"
New-ItemProperty -Path $gpoPath -Name "DisableAntiSpyware" -Value 1 -PropertyType DWORD -Force | Out-Null

# Equivalent of "Turn off real-time protection"
New-ItemProperty -Path $rtpPath -Name "DisableRealtimeMonitoring" -Value 1 -PropertyType DWORD -Force | Out-Null

Write-Host "Registry keys (GPO equivalent) applied." -ForegroundColor Green

Write-Host "`n=== Step 3: disabling Defender scheduled tasks ===" -ForegroundColor Cyan

$taskNames = @(
    "Windows Defender Cache Maintenance",
    "Windows Defender Cleanup",
    "Windows Defender Scheduled Scan",
    "Windows Defender Verification"
)

foreach ($name in $taskNames) {
    try {
        Get-ScheduledTask -TaskPath "\Microsoft\Windows\Windows Defender\" -TaskName $name -ErrorAction Stop |
            Disable-ScheduledTask -ErrorAction Stop | Out-Null
        Write-Host "  - $name : disabled" -ForegroundColor Green
    }
    catch {
        Write-Warning "  - $name : failed (already disabled, missing, or Tamper Protection active)"
    }
}

Write-Host "`n=== Part 1 complete ===" -ForegroundColor Cyan
Write-Host "Next step: reboot into SAFE MODE (msconfig > Boot > Safe boot > Minimal)"
Write-Host "then run 2-disable-defender-services-en.ps1"
