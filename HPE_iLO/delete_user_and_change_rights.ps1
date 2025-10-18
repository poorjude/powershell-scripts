Import-Module HPEiLOCmdlets

# Загружаем список IP из файла
$iLO_IP_list = (Get-Content -Path ".\delete_user_and_change_rights_input.txt")

# Включаем стандартное логирование
Enable-HPEiLOLog
# Файлы с логами лежат тут: C:\Program Files\Hewlett-Packard\PowerShell\Modules\HPEiLOCmdlets\Logs\

# Проходимся по каждому IP из списка
foreach ($iLO_IP in $iLO_IP_list) {
    # Установка соединения (через явное указание логина и пароля администратора)
    $admin_username = "username"
    $admin_password = "password"
    $connection = Connect-HPEiLO -Address $iLO_IP -Username $admin_username -Password $admin_password -DisableCertificateAuthentication:$true -Timeout 60 -Verbose

    # Начинаем удаление лишнего пользователя
    $usertodelete_username = "usertodelete"
    # Проверяем, что он существует
    $userInfo = (Get-HPEiLOUser -Connection $connection).UserInformation
    foreach ($curr_userInfo in $userInfo) {
        if ($curr_userInfo.LoginName -eq $usertodelete_username) {
            # Удаляем
            $removeHPEiLOUser_result = Remove-HPEiLOUser -connection $connection -LoginName $usertodelete_username
            # Проверяем, что пользователь удалён корректно, и если нет - записываем в ошибки
            if ($removeHPEiLOUser_result.Status -eq "ERROR") { Write-Error -Message ("An error occured while deleting the user in the iLO with the address " + $iLO_IP) }
            # Выходим из цикла
            break
        }
    }

    # Меняем пользователю права
    $usertochange_username = "usertochange"
    $setHPEiLOUser_result = Set-HPEiLOUser -connection $connection -LoginName $usertochange_username `
    -RemoteConsolePrivilege No -VirtualMediaPrivilege No -iLOConfigPrivilege No -VirtualPowerAndResetPrivilege No -UserConfigPrivilege No
    # -HostStorageConfigPrivilege No -HostBIOSConfigPrivilege No -HostNICConfigPrivilege No -SystemRecoveryConfigPrivilege No -LoginPrivilege Yes 
    # Проверяем, что права были изменены корректно, и если нет - записываем в ошибки
    if ($setHPEiLOUser_result.Status -eq "ERROR") {
        Write-Error -Message ("An error occured while changing the user rights in the iLO with the address " + $iLO_IP)
    }

    # Отключаемся от iLO
    Disconnect-HPEiLO -Connection $connection

    # Сообщаем об ошибках (записывается в файл по пути $error_logs_path)
    if($Error.Count -ne 0 ) {
        $error_logs_path = ".\ERROR_LOGS_iLO_script.txt"
        Add-Content -Path $error_logs_path -Value (Get-Date)
        Add-Content -Path $error_logs_path -Value "The following errors occurred in the script:"
        Add-Content -Path $error_logs_path -Value $Error
        Add-Content -Path $error_logs_path -Value ""
        Write-Host "The following errors occurred in the script:"
        Write-Host $Error

        $Error.Clear()
    }
}

# Выключаем стандартное логирование
Disable-HPEiLOLog