Import-Module HPEiLOCmdlets

# Включаем стандартное логирование
Enable-HPEiLOLog
# Файлы с логами лежат тут: C:\Program Files\Hewlett-Packard\PowerShell\Modules\HPEiLOCmdlets\Logs\

# Ищем iLO версий 4, 5 и 6 в указанном диапазоне IP
$found_HPEiLO = Find-HPEiLO "192.168.210.1-254" | 
    Where-Object { $_.PN -like "*iLO 4*" -or $_.PN -like "*iLO 5*" -or $_.PN -like "*iLO 6*" }

# Запускаем цикл, где проходимся по каждому найденному iLO
foreach ($curr_iLO in $found_HPEiLO) {
    # Установка соединения (через явное указание логина и пароля)
    $iLO_username = "username"
    $iLO_password = "password"
    $connection = Connect-HPEiLO -Address $curr_iLO.IP -Username $iLO_username -Password $iLO_password -DisableCertificateAuthentication:$true -Timeout 60 -Verbose

    # Добавляем нового пользователя и выдаём ему нужные права
    $iLO_newuser_username = "new_username"
    $iLO_newuser_password = "new_password"
    $addHPEiLOUser_result = Add-HPEiLOUser -connection $connection -LoginName $iLO_newuser_username -Username $iLO_newuser_username -Password $iLO_newuser_password `
    -IloConfigPrivilege Yes -UserConfigPrivilege No -RemoteConsolePrivilege No -VirtualMediaPrivilege No -VirtualPowerAndResetPrivilege No # -LoginPrivilege Yes

    # Проверяем, что пользователь добавился корректно, и если нет - записываем в ошибки
    if ($addHPEiLOUser_result.Status -eq "ERROR") {
        Write-Error -Message ("An error occured while adding the user in the iLO with the address " + $addHPEiLOUser_result.IP)
    }

    # Отключаемся от iLO
    Disconnect-HPEiLO -Connection $connection

    # Сообщаем об ошибках (записывается в файл по пути $error_logs_path)
    if ($Error.Count -ne 0) {
        $error_logs_path = ".\ERROR_LOGS_iLO_script.txt"
        Add-Content -Path $error_logs_path -Value (Get-Date)
        Add-Content -Path $error_logs_path -Value ("The following errors occurred in the script with the iLO IP " + $curr_iLO.IP)
        Add-Content -Path $error_logs_path -Value $Error
        Add-Content -Path $error_logs_path -Value ""
        Write-Host ("The following errors occurred in the script with the iLO IP " + $curr_iLO.IP)
        Write-Host $Error

        $Error.Clear()
    }
}

# Выключаем стандартное логирование
Disable-HPEiLOLog