 start-process "msiexec.exe" -argumentlist "/x {6D1790DD-3328-4493-82A0-5BEB7B5C8446} /quiet /noreboot" -Wait # sysmon agent
 start-process "MsiExec.exe" -argumentlist "/X {A7577602-CD86-4C1B-95F8-6469436C029B} /quiet /noreboot" -Wait # wazuh agent
# remove arctic wolf apps - all	 
 $Programs = Get-WmiObject -Class Win32_product | Where {$_.name -like "arctic*"}
	ForEach ($Program in $Programs) 
	{
		$Program.Uninstall()
	}
