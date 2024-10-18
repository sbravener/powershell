#Checks the Manufacturer  of the computer
$Manufacturer  = Get-ItemPropertyValue 'HKLM:\SYSTEM\CurrentControlSet\Control\SystemInformation' 'SystemManufacturer'

#If Manufactuer matches "Dell Inc." continue with the script, else terminate
if ($Manufacturer.equals("Dell Inc."))
{
     #Dell Command Update CLI command to check for updates and places the file in the temp folder on the C drive
     &"C:\Program Files\Dell\CommandUpdate\dcu-cli.exe" /scan -updateType="bios,firmware,driver,application,others" -report=C:\Temp\UpdatesReport.xml

     Start-Sleep -Seconds 60

     #Grabs current date in a format the DCU-CLI requires and adds 5 minutes to it. This is used for the notification sent out by the DCU if an reboot is required.
     $notiDate = (get-date).AddMinutes(2).ToString("MM/dd/yyyy,HH:mm")
     
     #Destination where report is located
     $DCU_Report = "C:\Temp\UpdatesReport.xml"

     if(Test-Path "$DCU_report\DCUApplicableUpdates.xml")
     {
          switch ($LASTEXITCODE)
          {
               #statment that checks for exit code 0, this means updates were found and it proceeds to the Remediation script.
               0 {"Exit Code: $($LASTEXITCODE) Update Found, Proceeding to Remediation Script!"; exit 1}
               #statement that checks for exit code 1, A reboot was required from the execution of an operation.  Reboot the system to complete the operation.
               1 {"Exit Code: $($LASTEXITCODE) Computer needs to be rebooted to install recently installed updates!"; &"C:\Program Files\Dell\CommandUpdate\dcu-cli.exe" /customnotification -heading="Reboot Required!" -body="Dell Updates were just installed to your computer, please reboot your computer!" -timestamp="$notiDate"; exit 0}
               #statement that checks for exit codes 1 & 5, A reboot was pending from a previous operation.
               5 {"Exit Code: $($LASTEXITCODE) Computer needs to be rebooted to install previously installed updates!"; &"C:\Program Files\Dell\CommandUpdate\dcu-cli.exe" /customnotification -heading="Reboot Required!" -body="Your computer was unable to install new updates, because previous updates are pending a reboot. Please reboot your computer!" -timestamp="$notiDate"; exit 0}
               #statement that checks for exit code 500, this means no updates were found for the system.
               500 {"Exit Code: $($LASTEXITCODE) No Updates Found!"; &"C:\Program Files\Dell\CommandUpdate\dcu-cli.exe" /customnotification -heading="No Updates Found!" -body="No Dell updates were found for your device!" -timestamp="$notiDate"; exit 0}
               #catch all for any other exit codes
               default {"Exit Code: $($LASTEXITCODE) Please Look Up Exit Code"; exit 0}
          }
     }
     #if an XML file is not created that means no updates were found
     else
     {
         Write-Output "No XML file in folder, aka no updates found!"
         exit 0
     }
}
else
{
     Write-Output "Computer is not a Dell Computer"
     exit 0
}