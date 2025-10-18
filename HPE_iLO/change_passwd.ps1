Import-Module HPEiLOCmdlets

# Загружаем список IP из файла
$iLO_IP_list = (Get-Content -Path ".\change_passwd_input.txt")

# Включаем стандартное логирование
Enable-HPEiLOLog
# Файлы с логами лежат тут: C:\Program Files\Hewlett-Packard\PowerShell\Modules\HPEiLOCmdlets\Logs\

# Проходимся по каждому IP из списка
foreach ($iLO_IP in $iLO_IP_list) {
    # Текущие креды пользователя и новый пароль
    $username = "username"
    $old_password = "old_password123"
    $new_password = "new_password123"

    # Установка соединения
    $connection = Connect-HPEiLO -Address $iLO_IP -Username $username -Password $old_password -DisableCertificateAuthentication:$true -Timeout 60 -Verbose

    # Меняем пароль
    $setHPEiLOUser_result = Set-HPEiLOUser -Connection $connection -LoginName $username -NewPassword $new_password

    # Проверяем, что пароль изменился корректно, и если нет - записываем в ошибки
    if ($setHPEiLOUser_result.Status -eq "ERROR") {
        Write-Error -Message ("An error occured while changing password in the iLO with the address " + $iLO_IP)
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