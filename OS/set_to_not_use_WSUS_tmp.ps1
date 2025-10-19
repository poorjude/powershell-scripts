Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "UseWUServer" -Value 0
Restart-Service -Name wuauserv

Write-Host "The host was set to not use a WSUS server."
Read-Host "After installing updates press Enter to return to the previous settings."

Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "UseWUServer" -Value 1
Restart-Service -Name wuauserv