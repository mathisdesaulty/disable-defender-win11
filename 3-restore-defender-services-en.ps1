<#
.SYNOPSIS
    Restore Windows Defender: services (default values) + remove GPO keys + re-enable scheduled tasks.
    Run the services part in Safe Mode too (same PPL constraint as when disabling).

.NOTES
    Default values as listed in the IT-Connect article:
    Sense:3, WdBoot:0, WdFilter:0, WdNisDrv:3, WdNisSvc:3, WinDefend:2
#>

#Requires -RunAsAdministrator

Write-Host "=== Restoring Defender services ===" -ForegroundColor Cyan

$originalValues = @{
    "Sense"     = 3
    "WdBoot"    = 0
    "WdFilter"  = 0
    "WdNisDrv"  = 3
    "WdNisSvc"  = 3
    "WinDefend" = 2
}

foreach ($svc in $originalValues.Keys) {
    $path = "HKLM:\SYSTEM\CurrentControlSet\Services\$svc"
    if (Test-Path $path) {
        try {
            Set-ItemProperty -Path $path -Name "Start" -Value $originalValues[$svc] -Force -ErrorAction Stop
            Write-Host "  - $svc : restored to Start=$($originalValues[$svc])" -ForegroundColor Green
        }
        catch {
            Write-Warning "  - $svc : FAILED - $($_.Exception.Message) (retry in Safe Mode if needed)"
        }
    }
}

Write-Host "`n=== Removing GPO registry keys ===" -ForegroundColor Cyan

$gpoPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"
$rtpPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection"

Remove-ItemProperty -Path $gpoPath -Name "DisableAntiSpyware" -ErrorAction SilentlyContinue
Remove-ItemProperty -Path $rtpPath -Name "DisableRealtimeMonitoring" -ErrorAction SilentlyContinue
Write-Host "GPO keys removed (if they existed)." -ForegroundColor Green

Write-Host "`n=== Re-enabling scheduled tasks ===" -ForegroundColor Cyan

$taskNames = @(
    "Windows Defender Cache Maintenance",
    "Windows Defender Cleanup",
    "Windows Defender Scheduled Scan",
    "Windows Defender Verification"
)

foreach ($name in $taskNames) {
    try {
        Get-ScheduledTask -TaskPath "\Microsoft\Windows\Windows Defender\" -TaskName $name -ErrorAction Stop |
            Enable-ScheduledTask -ErrorAction Stop | Out-Null
        Write-Host "  - $name : re-enabled" -ForegroundColor Green
    }
    catch {
        Write-Warning "  - $name : failed or already enabled"
    }
}

Write-Host "`nAlso remember to re-enable Tamper Protection and real-time protection from Windows Security." -ForegroundColor Yellow
Write-Host "Reboot to fully apply the changes."
