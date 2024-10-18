# Get the script start time
$starttime = Get-Date
Write-Host "Script started at $starttime"

# Import Configuration Manager PowerShell module
try {
    Import-Module (Join-Path $(Split-Path $env:SMS_ADMIN_UI_PATH) ConfigurationManager.psd1)
} catch [System.Exception] {
    Write-Warning "Unable to load the Configuration Manager PowerShell module from $env:SMS_ADMIN_UI_PATH"
    break
}

# Get the site code
$SiteCode = Get-PSDrive -PSProvider CMSITE
Set-Location -Path "$($SiteCode.Name):\"

# Get the current date components for folder structure
$currentYear = Get-Date -Format "yyyy"
$currentMonthName = Get-Date -Format "MMMM"
$currentDay = Get-Date -Format "yyyy-MM-dd"

# Define the root backup path
$rootBackupPath = "C:\Users\daniel.cuestas\Downloads\TS Backups"

# Create year, month, and day folders
$yearFolderPath = Join-Path -Path $rootBackupPath -ChildPath $currentYear
$monthFolderPath = Join-Path -Path $yearFolderPath -ChildPath $currentMonthName
$dayFolderPath = Join-Path -Path $monthFolderPath -ChildPath $currentDay

# Ensure the directories exist
if (-not (Test-Path -Path $yearFolderPath)) {
    New-Item -Path $yearFolderPath -ItemType Directory
}
if (-not (Test-Path -Path $monthFolderPath)) {
    New-Item -Path $monthFolderPath -ItemType Directory
}
if (-not (Test-Path -Path $dayFolderPath)) {
    New-Item -Path $dayFolderPath -ItemType Directory
}

# Get list of all task sequences
$ts = Get-CMTaskSequence | select Name

foreach ($name in $ts) {
    # Replace any unsupported characters with empty space for folder name
    $tsname = $name.Name.Replace(":", "").Replace(",", "").Replace("*", "").Replace("?", "").Replace("\", "").Replace("/", "").Replace("<", "").Replace(">", "")
    
    # Export the task sequences to the day folder
    $exportFilePath = Join-Path -Path $dayFolderPath -ChildPath ($tsname + ".zip")
    Export-CMTaskSequence -Name $name.Name -WithDependence $false -WithContent $false -ExportFilePath $exportFilePath -Force
}

# Delete backups older than 2 months
$twoMonthsAgo = (Get-Date).AddMonths(-2)
Get-ChildItem -Path $rootBackupPath -Recurse -Directory | Where-Object { $_.CreationTime -lt $twoMonthsAgo } | Remove-Item -Recurse -Force

# Get script end time
$endtime = Get-Date

# Get the script execution time (total)
$Scripttime = ($endtime - $starttime).Seconds
Write-Host "Script ended at $endtime with execution time of $Scripttime seconds"