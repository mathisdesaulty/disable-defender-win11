<#
.SYNOPSIS
    Checkup of Windows Defender status: Tamper Protection, real-time protection,
    services/drivers, GPO registry keys, scheduled tasks.

.DESCRIPTION
    Read-only script (no changes made). Run in an elevated PowerShell session
    for full visibility (some HKLM values may be hidden otherwise).
#>

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " WINDOWS DEFENDER CHECKUP" -ForegroundColor Cyan
Write-Host "=========================================`n" -ForegroundColor Cyan

# --- 1. General status via Get-MpComputerStatus ---
Write-Host "--- General status ---" -ForegroundColor Yellow
try {
    $status = Get-MpComputerStatus -ErrorAction Stop
    [PSCustomObject]@{
        "Tamper Protection"        = $status.IsTamperProtected
        "Real-time protection"     = $status.RealTimeProtectionEnabled
        "Antivirus (AM) service"   = $status.AMServiceEnabled
        "Cloud protection"         = $status.MAPSReporting
        "Behavior monitoring"      = $status.BehaviorMonitorEnabled
        "IOAV protection"          = $status.IoavProtectionEnabled
        "Script scanning (NIS)"    = $status.NISEnabled
        "Engine version"           = $status.AMEngineVersion
        "Last signature update"    = $status.AntivirusSignatureLastUpdated
    } | Format-List
}
catch {
    Write-Warning "Get-MpComputerStatus unavailable (Defender may already be disabled at the service level): $($_.Exception.Message)"
}

# --- 2. Preferences via Set-MpPreference ---
Write-Host "--- Preferences (Set-MpPreference) ---" -ForegroundColor Yellow
try {
    $pref = Get-MpPreference -ErrorAction Stop
    [PSCustomObject]@{
        "Realtime monitoring disabled" = $pref.DisableRealtimeMonitoring
        "Behavior monitoring disabled" = $pref.DisableBehaviorMonitoring
        "IOAV protection disabled"     = $pref.DisableIOAVProtection
        "Script scanning disabled"     = $pref.DisableScriptScanning
        "MAPS reporting"               = $pref.MAPSReporting
        "Sample submission consent"    = $pref.SubmitSamplesConsent
    } | Format-List
}
catch {
    Write-Warning "Get-MpPreference unavailable: $($_.Exception.Message)"
}

# --- 3. Services / drivers ---
Write-Host "--- Services and drivers (registry Start value) ---" -ForegroundColor Yellow
Write-Host "(0=Boot,1=System,2=Automatic,3=Manual,4=Disabled)`n"

$services = "Sense", "WdBoot", "WdFilter", "WdNisDrv", "WdNisSvc", "WinDefend"
$results = foreach ($svc in $services) {
    $path = "HKLM:\SYSTEM\CurrentControlSet\Services\$svc"
    $running = Get-Service -Name $svc -ErrorAction SilentlyContinue
    [PSCustomObject]@{
        Service      = $svc
        StartReg     = if (Test-Path $path) { (Get-ItemProperty -Path $path -Name Start -ErrorAction SilentlyContinue).Start } else { "N/A" }
        CurrentState = if ($running) { $running.Status } else { "Not found" }
    }
}
$results | Format-Table -AutoSize

# --- 4. GPO registry keys ---
Write-Host "--- Group Policy registry keys ---" -ForegroundColor Yellow
$gpoPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"
$rtpPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection"

$disableAV  = (Get-ItemProperty -Path $gpoPath -Name "DisableAntiSpyware" -ErrorAction SilentlyContinue).DisableAntiSpyware
$disableRTP = (Get-ItemProperty -Path $rtpPath -Name "DisableRealtimeMonitoring" -ErrorAction SilentlyContinue).DisableRealtimeMonitoring

[PSCustomObject]@{
    "DisableAntiSpyware (GPO)"        = if ($null -ne $disableAV) { $disableAV } else { "Not set" }
    "DisableRealtimeMonitoring (GPO)" = if ($null -ne $disableRTP) { $disableRTP } else { "Not set" }
} | Format-List

# --- 5. Scheduled tasks ---
Write-Host "--- Defender scheduled tasks ---" -ForegroundColor Yellow
$taskNames = @(
    "Windows Defender Cache Maintenance",
    "Windows Defender Cleanup",
    "Windows Defender Scheduled Scan",
    "Windows Defender Verification"
)

foreach ($name in $taskNames) {
    try {
        $task = Get-ScheduledTask -TaskPath "\Microsoft\Windows\Windows Defender\" -TaskName $name -ErrorAction Stop
        Write-Host ("  - {0,-40} : {1}" -f $name, $task.State)
    }
    catch {
        Write-Host ("  - {0,-40} : not found" -f $name) -ForegroundColor DarkGray
    }
}

Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host " CHECKUP COMPLETE" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
