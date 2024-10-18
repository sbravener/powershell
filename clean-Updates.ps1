# Define log file path
$logDirectory = "C:\Windows\Temp\SFC_DISM_Logs"
$logFile = "$logDirectory\SFC_DISM_Log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
 
# Create log directory if not exists
if (-Not (Test-Path $logDirectory)) {
    New-Item -Path $logDirectory -ItemType Directory | Out-Null
}
 
# Function to write logs
function Write-Log {
    param (
        [string]$message
    )
    $timeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timeStamp - $message"
    Write-Output $logMessage
    Add-Content -Path $logFile -Value $logMessage
}
 
# Function to check and rename folders if they are older than 35 days
function Rename-FolderIfOld {
    param (
        [string]$folderPath,
        [string]$backupFolderName
    )
    if (Test-Path $folderPath) {
        $lastModified = (Get-Item $folderPath).LastWriteTime
        $daysOld = (Get-Date) - $lastModified
 
        if ($daysOld.Days -gt 35) {
            Write-Log "$folderPath is older than 35 days. Removing if backup exists and renaming the folder."
            # If backup exists, remove it
            $backupFolderPath = "$Env:Windir\$backupFolderName"
            if (Test-Path $backupFolderPath) {
                Write-Log "$backupFolderPath already exists. Removing it."
                Remove-Item $backupFolderPath -Recurse -Force
            }
            # Rename the folder to .bak
            Rename-Item -Path $folderPath -NewName $backupFolderName
            Write-Log "Renamed $folderPath to $backupFolderName."
        } else {
            Write-Log "$folderPath is not older than 35 days. No action taken."
        }
    } else {
        Write-Log "$folderPath does not exist. No action needed."
    }
}
 
# Stop and start services function
function Restart-UpdateServices {
    Write-Log "Stopping Windows Update services..."
    # Stop dependent services
    $DependentService = Get-Service -Name cryptsvc -DependentServices | Where-Object Status -eq 'Running'
    if ($DependentService) {
        Write-Log "Stopping dependent services: $($DependentService.Name)"
        Stop-Service $DependentService -Force
    }
 
    # Stop required services
    Stop-Service -Name wuauserv -Force
    Stop-Service -Name cryptsvc -Force
    Stop-Service -Name bits -Force
    Write-Log "Services stopped successfully."
}
 
# Start services function
function Start-UpdateServices {
    Write-Log "Starting Windows Update services..."
 
    # Start required services
    Start-Service -Name cryptsvc
    Start-Service -Name bits
    Start-Service -Name wuauserv
    # Restart dependent services if they were running
    $DependentService = Get-Service -Name cryptsvc -DependentServices | Where-Object Status -eq 'Stopped'
    if ($DependentService) {
        Start-Service $DependentService
        Write-Log "Dependent services restarted."
    }
 
    Write-Log "Windows Update services started successfully."
}
 
# Run SFC scan
function Run-SFCScan {
    Write-Log "Starting SFC scan..."
    try {
        $sfcResult = sfc /scannow
        Write-Log "SFC scan completed successfully."
    } catch {
        Write-Log "SFC scan encountered an error: $_"
    }
}
 
# Run DISM CheckHealth
function Run-DISMCheckHealth {
    Write-Log "Starting DISM CheckHealth..."
    try {
        $checkHealthResult = dism /online /cleanup-image /checkhealth
        Write-Log "DISM CheckHealth completed successfully."
    } catch {
        Write-Log "DISM CheckHealth encountered an error: $_"
    }
}
 
# Run DISM ScanHealth
function Run-DISMScanHealth {
    Write-Log "Starting DISM ScanHealth..."
    try {
        $scanHealthResult = dism /online /cleanup-image /scanhealth
        Write-Log "DISM ScanHealth completed successfully."
    } catch {
        Write-Log "DISM ScanHealth encountered an error: $_"
    }
}
 
# Run DISM RestoreHealth
function Run-DISMRestoreHealth {
    Write-Log "Starting DISM RestoreHealth..."
    try {
        $restoreHealthResult = dism /online /cleanup-image /restorehealth
        Write-Log "DISM RestoreHealth completed successfully."
    } catch {
        Write-Log "DISM RestoreHealth encountered an error: $_"
    }
}
 
# Main script execution
Write-Log "===================="
Write-Log "Starting monthly system scan and repair..."
Write-Log "===================="
 
# Stop services before renaming folders
Restart-UpdateServices
 
# Check and rename folders if they are older than 35 days
Rename-FolderIfOld -folderPath "$Env:Windir\SoftwareDistribution" -backupFolderName "SoftwareDistribution.bak"
Rename-FolderIfOld -folderPath "$Env:Windir\System32\catroot2" -backupFolderName "catroot2.bak"
 
# Start services after renaming folders
Start-UpdateServices
 
# Run SFC scan
Run-SFCScan
 
# Run DISM scans
Run-DISMCheckHealth
Run-DISMScanHealth
Run-DISMRestoreHealth
 
Write-Log "===================="
Write-Log "System scan and repair completed."
Write-Log "===================="
 
# Output log path for reference
Write-Host "Log file created at: $logFile"