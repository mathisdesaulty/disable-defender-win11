<#
.SYNOPSIS
    Disable Windows Defender services/drivers - PART 2/2.
    RUN ONLY IN SAFE MODE (Minimal), otherwise it fails with PermissionDenied/PPL.

.DESCRIPTION
    Sets Start=4 (Disabled) on the services listed in the IT-Connect article:
    Sense, WdBoot, WdFilter, WdNisDrv, WdNisSvc, WinDefend.

.NOTES
    - Prerequisite: Tamper Protection already disabled (otherwise silently ignored).
    - After running: exit Safe Mode (msconfig, uncheck Safe boot) then reboot normally.
    - To revert, use 3-restore-defender-services-en.ps1.
#>

#Requires -RunAsAdministrator

$services = @{
    "Sense"     = 4
    "WdBoot"    = 4
    "WdFilter"  = 4
    "WdNisDrv"  = 4
    "WdNisSvc"  = 4
    "WinDefend" = 4
}

Write-Host "=== Disabling Defender services (registry, Start=4) ===" -ForegroundColor Cyan

foreach ($svc in $services.Keys) {
    $path = "HKLM:\SYSTEM\CurrentControlSet\Services\$svc"
    if (Test-Path $path) {
        try {
            Set-ItemProperty -Path $path -Name "Start" -Value $services[$svc] -Force -ErrorAction Stop
            Write-Host "  - $svc : Start=$($services[$svc])" -ForegroundColor Green
        }
        catch {
            Write-Warning "  - $svc : FAILED - $($_.Exception.Message)"
            Write-Warning "    Check that you are in Safe Mode and that Tamper Protection is disabled."
        }
    }
    else {
        Write-Warning "  - $svc : key not found (service not present on this system)"
    }
}

Write-Host "`n=== Done ===" -ForegroundColor Cyan
Write-Host "Exit Safe Mode (msconfig > Boot > uncheck Safe boot) then reboot normally."
