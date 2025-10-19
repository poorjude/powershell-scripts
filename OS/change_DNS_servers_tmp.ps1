# В эту переменную записываем полное название адаптера, для которого будем менять DNS-сервера
$netAdapterName = "Ethernet 3"

Get-NetAdapter | Where-Object { $_.Name -eq $netAdapterName } | Set-DnsClientServerAddress -ServerAddresses ("8.8.8.8", "8.8.4.4")
Clear-DnsClientCache

Write-Host "The DNS servers were set to 8.8.8.8, 8.8.4.4. The DNS cache was flushed."
Read-Host "Press Enter to return to the previous DNS settings"

# Get-NetAdapter | Where-Object { $_.Name -eq $netAdapterName } | Set-DnsClientServerAddress -ResetServerAddresses
Get-NetAdapter | Where-Object { $_.Name -eq $netAdapterName } | Set-DnsClientServerAddress -ServerAddresses ("192.168.10.33", "192.168.10.34")
Clear-DnsClientCache