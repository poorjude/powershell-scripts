Import-Module ActiveDirectory

# Указываем файл .prom, в который будем писать метрики
$promFile = "C:\Program Files\windows_exporter\textfile_inputs\ad_availability.prom"
# Первично заполняем файл
Set-Content -Path $promFile -Encoding ASCII `
    -Value "# HELP ad_availability Check AD DCs availability: TCP connection, LDAP query, DNS query"
Add-Content -Path $promFile -Value "# TYPE ad_availability gauge"

# Указываем домены, которые будем проверять
$Domains = @('domain1.local', 'domain2.local', 'domain3.local')

foreach ($Domain in $Domains) {
    # Получаем информацию о DC
    $Error.Clear()
    $DCs = @()
    $DCs = Get-ADDomain -Identity $Domain | Select-Object -ExpandProperty ReplicaDirectoryServers
    if ($Error.Count -eq 0) { $bit = 1 } else { $bit = 0 }

    Add-Content -Path $promFile -Value "ad_availability{domain=""$Domain"",query=""initial_query""} $bit"

    # Если не удалось получить список DC, то пропускаем остальные проверки
    if(-not [bool]$bit) { continue }

    foreach ($DC in $DCs) {
        # Подключаемся к портам по TCP
        $ports = @(
            389, # LDAP
            636, # LDAPS
            139, # SMB
            445, # SMB
            53   # DNS
        )
        foreach ($port in $ports) {
            $bit = [int]((Test-NetConnection -ComputerName $DC -Port $port).TcpTestSucceeded)
            Add-Content -Path $promFile -Value "ad_availability{domain=""$Domain"",dc=""$DC"",query=""tcp_port_$port""} $bit"
        }

        # Делаем LDAP-запрос
        Get-ADDomain -Server $DC
        $bit = [int]($?)
        Add-Content -Path $promFile -Value "ad_availability{domain=""$Domain"",dc=""$DC"",query=""ldap_query""} $bit"

        # Проверяем доступность SYSVOL по SMB
        $bit = [int](Test-Path "\\$DC\SYSVOL")
        Add-Content -Path $promFile -Value "ad_availability{domain=""$Domain"",dc=""$DC"",query=""ldap_query""} $bit"

        # Делаем DNS-запрос
        Resolve-DnsName -Name "yandex.ru" -Type A -Server $DC
        $bit = [int]($?)
        Add-Content -Path $promFile -Value "ad_availability{domain=""$Domain"",dc=""$DC"",query=""dns_resolve""} $bit"
   }
}