function Wait-ForReboot {
    param([string]$targetHost)

    # Ждем, пока перезагрузится хост
    $rebooted = $false
    for ($i = 0; $i -lt 120; $i++) {
        $Error.Clear()
        Start-Sleep -Seconds 5
        Test-Connection $targetHost -Count 2 >$null 2>&1
        if ($Error.Count -gt 0) {
            $Error.Clear()
            continue
        } else {
            $rebooted = $true
            break
        }
    }

    # Если не перезагрузился - вызываем ошибку
    if (-not $rebooted) {
        throw "Host $targetHost did not reboot in 10 minutes!"
    }

    # Ожидаем, пока ОС загрузится целиком (т.к. пинг начинает проходить раньше, чем загрузятся все службы)
    Start-Sleep -Seconds 30
}



# Hostname/FQDN/IP целевого хоста (если ниже будем менять имя хоста - лучше указывать IP)
$target = "192.168.44.51"
# Вводим credentials локального администратора на хосте
$cred = Get-Credential -Message "Enter the credentials for connection to $target"



# Название сетевого адаптера, для которого будем менять DNS-сервера
$netAdapterName = "vEthernet (Virtual Switch)"
# IP локальных DNS-серверов
$localDnsServersIp = "192.168.10.33", "192.168.10.34"
# IP публичных DNS-серверов
$publicDnsServersIp = "8.8.8.8", "8.8.4.4"

# Меняем DNS-сервера на публичные
Invoke-Command -ComputerName $target -Credential $cred -ScriptBlock {
    Get-NetAdapter | 
        Where-Object { $_.Name -eq $using:netAdapterName } | 
        Set-DnsClientServerAddress -ServerAddresses $using:publicDnsServersIp
    Clear-DnsClientCache
}

# Здесь: устанавливаем обновления вручную и нажимаем Enter, когда всё будет готово
# TODO: обращаться к службе Windows Update через COM-объект, автоматизировать установку обновлений
Write-Host "The DNS servers were set to public $publicDnsServersIp. The DNS cache was flushed."
Read-Host "Press Enter to return to the previous DNS settings after the updates are installed"

# Меняем DNS-сервера на локальные
Invoke-Command -ComputerName $target -Credential $cred -ScriptBlock { 
    Get-NetAdapter | 
        Where-Object { $_.Name -eq $using:netAdapterName } | 
        # Set-DnsClientServerAddress -ResetServerAddresses
        Set-DnsClientServerAddress -ServerAddresses $using:localDnsServersIp
    Clear-DnsClientCache
}



# Выставляем все необходимые настройки ОС
$newHostName = "NewServerName01"
Invoke-Command -ComputerName $target -Credential $cred -ScriptBlock {
    # Присваиваем новое имя хосту
    Rename-Computer -NewName $using:newHostName
    # Устанавливаем часовой пояс
    Set-TimeZone -Id "Russian Standard Time"
    # Отключаем брандмауэр
    netsh advfirewall set allprofiles state off
    # Разрешаем подключение по RDP
    Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0
    #  Создаём нужные директории
    New-Item -ItemType Directory -Path "C:\Files" -Force
    New-Item -ItemType Directory -Path "D:\Backup" -Force
    # Отключаем LUA
    New-ItemProperty -Path HKLM:Software\Microsoft\Windows\CurrentVersion\policies\system -Name EnableLUA -PropertyType DWord -Value 0 -Force
    # Удаляем Windows Defender
    Uninstall-WindowsFeature -Name Windows-Defender
}
# Перезагружаем хост и ждём включения
Restart-Computer -ComputerName $target -Credential $cred
Wait-ForReboot -TargetHost $target



# Проверка на Evaluation + смена на обычную версию + рестарт
$osVers = Invoke-Command -ComputerName $target -Credential $cred -ScriptBlock { Get-ComputerInfo | Select-Object OsName }
if ($osVers -like "*eval*") {
    Invoke-Command -ComputerName $target -Credential $cred -ScriptBlock {
        # Указываем ключ KMS-активации для Windows Server 2019 Standard (!)
        dism /online /set-edition:ServerStandard /productkey:N69G4-B89J2-4G8F4-WWYCC-J464C /accepteula
    }

    # Перезагружаем хост и ждём включения
    Restart-Computer -ComputerName $target -Credential $cred
    Wait-ForReboot -TargetHost $target
}

# Активируем ОС через KMS-сервер
Invoke-Command -ComputerName $target -Credential $cred -ScriptBlock {
    # Указываем KMS-сервер активации и порт
    slmgr /skms "192.168.10.45:1688"
    # Активируем ОС
    slmgr /ato
}



# Установка ПО
Invoke-Command -ComputerName $target -Credential $cred -ScriptBlock {
    # Установка .exe
    &"\\FileServer01\Soft\Program01\setup.exe --silent"
    &"\\FileServer01\Soft\Program02\setup.exe -s"
    # Установка .msi
    msiexec /i "\\FileServer01\Soft\Program03\setup.msi"
}



# Ввод в домен и рестарт
$domain = "domain.local"
$domainCred = Get-Credential -Message "Enter the credentials for the domain $domain"
Add-Computer -ComputerName $target -LocalCredential $cred -DomainName $domain -Credential $domainCred -Restart
Wait-ForReboot -TargetHost $target