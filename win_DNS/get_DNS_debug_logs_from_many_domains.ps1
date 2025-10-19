Import-Module DnsServer

# Указываем DNS-серверы
$dns_servers = @(
    "dc1.domain1.local"
    "dc2.domain1.local"
    "dc1.domain2.local"
    "dc1.domain3.local"
    "dc1.domain4.local"
    "dc2.domain4.local"
)

# Вводим credentials для каждого домена
$domain1_creds = Get-Credential -Message "Enter creds for domain1.local DNS-servers"
$domain2_creds = Get-Credential -Message "Enter creds for domain2.local DNS-servers"
$domain3_creds = Get-Credential -Message "Enter creds for domain3.local DNS-servers"
$domain4_creds = Get-Credential -Message "Enter creds for domain4.local DNS-servers"

# Создаём папку, куда будем копировать логи DNS
$logFolderLocal = "C:\DNS_logs_" + (Get-Date -Format "dd.MM.yyyy_HH.mm.ss").ToString()
New-Item -Path $logFolderLocal -ItemType Directory -Force

foreach ($dns_server in $dns_servers) {
    # Выбираем, какие credentials будем использовать
    if ($dns_server -like "*.domain1.local") {
        $creds = $domain1_creds
    } elseif ($dns_server -like "*.domain2.local") {
        $creds = $domain2_creds
    } elseif ($dns_server -like "*.domain3.local") {
        $creds = $domain3_creds
    } elseif ($dns_server -like "*.domain4.local") {
        $creds = $domain4_creds
    } else {
        "Для данного хоста не найдены подходящие креды: $dns_server"
        continue
    }

    # Получаем месторасположение логов на DNS-сервере
    $logFilePathRemote = Invoke-Command -ComputerName $dns_server -Credential $creds {
        (Get-DnsServerDiagnostics).LogFilePath
    }

    $logFilePathLocal = $logFolderLocal + '\' + $dns_server + '.txt'

    # Копируем логи
    $session = New-PSSession -ComputerName $dns_server -Credential $creds
    Copy-Item -Path $logFilePathRemote -Destination $logFilePathLocal -FromSession $session -Verbose
    Remove-PSSession $session
}