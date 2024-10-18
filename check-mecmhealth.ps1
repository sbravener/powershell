# was auto-generated at '2/29/2024 2:37:59 PM'.

# Site configuration
$SiteCode = "COA" # Site code
$ProviderMachineName = "coat-sccm-01" # SMS Provider machine name

# Customizations
$initParams = @{}
#$initParams.Add("Verbose", $true) # Uncomment this line to enable verbose logging
#$initParams.Add("ErrorAction", "Stop") # Uncomment this line to stop the script on any errors

# Do not change anything below this line

# Import the ConfigurationManager.psd1 module
if((Get-Module ConfigurationManager) -eq $null) {
    Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams
}

# Connect to the site's drive if it is not already present
if((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName @initParams
}

# Set the current location to be the site code.
Set-Location "$($SiteCode):\" @initParams

# get computer info
Get-ComputerInfo |select windowsproductname

# primary site name
write-output "server name = $ProviderMachineName"

#clear screen
cls

#computer cpu
$cores=echo $env:NUMBER_OF_PROCESSORS
write-output "number of CPU cores = $cores"

#physical memory
$memory = Get-CimInstance win32_ComputerSystem | foreach {[math]::truncate($_.TotalPhysicalMemory /1GB)}
write-output "server memory = $memory"

# Drive info
Get-WmiObject -Class Win32_LogicalDisk | Select-Object -Property DeviceID, VolumeName, @{Label='FreeSpace (Gb)'; expression={($_.FreeSpace/1GB).ToString('F2')}}, @{Label='Total (Gb)'; expression={($_.Size/1GB).ToString('F2')}}, @{label='FreePercent'; expression={[Math]::Round(($_.freespace / $_.size) * 100, 2)}}|ft

# Show computer certificates that will expire in 90 days
Get-ChildItem -Path Cert:\LocalMachine\My | Select-Object -Property PSComputerName, Subject, @{n=’ExpireInDays’;e={($_.notafter – (Get-Date)).Days}} | Where-Object {$_.ExpireInDays -lt 90}

#MECM Info header
write-output "MECM Info"

#mecm version
$mecmbuild=Get-CmSite | Select-Object BuildNumber
write-output "MECM build $mecmbuild"



#get site status status

 Get-CMSiteComponent | Select-Object -ExpandProperty ComponentName -Unique | Sort-Object ComponentName | ForEach-Object {
    $errs  = $(Get-CMComponentStatusMessage -ComponentName $_ -Severity Error -StartTime $(Get-Date).AddHours(-24)).Count
    $warns = $(Get-CMComponentStatusMessage -ComponentName $_ -Severity Warning -StartTime $(Get-Date).AddHours(-24)).Count
    [pscustomobject]@{
        Component  = $_
        Errors     = $errs
        Warnings   = $warns
    }
}


#get date of last backup (db backup location must be filled in manually)
Write-host ""
Write-host ""
cd c:
Set-Location "\\coatfservdf\DTGHUB\SCCM_Backup\COABackup\"
$lastbackupdate = (Get-Item BackupDocument.xml).LastWriteTime
write-host "last site backup = "$lastbackupdate
Write-Output ""
Set-Location "$($SiteCode):\" @initParams


#run same info gathering on DPs
Write-output ""
Write-output ""
Write-Output " Distribution point info"
$distropoints=get-cmdistributionpointinfo | select-object servername -expandproperty servername
foreach ($element in $distropoints) {

Write-output "DP Name = "$element
Write-output ""

Invoke-Command -ComputerName $element -ScriptBlock {
    #computer cpu
    $cores=echo $env:NUMBER_OF_PROCESSORS
    write-output "number of CPU cores = $cores"
    Write-output ""

    #physical memory
    $memory = Get-CimInstance win32_ComputerSystem | foreach {[math]::truncate($_.TotalPhysicalMemory /1GB)}
    write-output "server memory = $memory"

    # Drive info
    Get-WmiObject -Class Win32_LogicalDisk | Select-Object -Property DeviceID, VolumeName, @{Label='FreeSpace (Gb)'; expression={($_.FreeSpace/1GB).ToString('F2')}}, @{Label='Total (Gb)'; expression={($_.Size/1GB).ToString('F2')}}, @{label='FreePercent'; expression={[Math]::Round(($_.freespace / $_.size) * 100, 2)}}|ft
    # certs
    write-output "certs expiring in next 90 days"
    write-output ""
    Get-ChildItem -Path Cert:\LocalMachine\My | Select-Object -Property PSComputerName, Subject, @{n=’ExpireInDays’;e={($_.notafter – (Get-Date)).Days}} | Where-Object {$_.ExpireInDays -lt 90}
    }

    }
