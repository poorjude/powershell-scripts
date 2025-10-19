Import-Module DnsServer

$TTL = "00:20:00"
$PrimaryZoneName = "domain.local"
$MiddleZoneName = ".subdomain.msk" # Указываем вместе с точкой в начале (или оставляем полностью пустую строку)

$allRecordsData = Get-Content -Path ".\add_many_DNS_records_input.csv" | ForEach-Object { 
    [PSCustomObject]@{ 
        IP = $_.Split(';')[0]
        Hostname = $_.Split(';')[1] 
    } 
}

foreach ($recordData in $allRecordsData ) {
    Add-DnsServerResourceRecordA `
      -ZoneName $PrimaryZoneName `
      -Name ($recordData.Hostname + $MiddleZoneName) `
      -IPv4Address $recordData.IP `
      -TimeToLive $TTL
}