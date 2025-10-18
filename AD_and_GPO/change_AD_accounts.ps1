Import-Module ActiveDirectory

# Указываем группы, в которые будет добавлен каждый пользователь
$groupsToAdd = @(
    "groupname1"
    "groupname2"
)
# Указываем OU, в которую будет перемещён каждый пользователь (в нотации LDAP)
$targetOU = "OU=Users subgroup,OU=Users,DC=test,DC=domain,DC=local"
# Указываем новый пароль для всех аккаунтов
$new_password = (Read-Host -Prompt "Введите новый пароль" -AsSecureString)
# Загружаем список УЗ
$accounts_list = (Get-Content -Path ".\change_AD_accounts_input.txt" -Encoding utf8)



foreach ($account in $accounts_list) {
    # Включаем УЗ, если отключена
    Enable-ADAccount -Identity $account
    Write-Host "$account включен"
    # Добавляем в группы
    foreach ($group in $groupsToAdd) {
        Add-ADGroupMember -Identity $group -Members $account
        Write-Host "$account добавлен в группу $group"
    }
    # Перемещаем в OU
    Get-ADUser -Identity $account |
        Move-ADObject -TargetPath $targetOU
    Write-Host "$account перемещен в OU $targetOU"
    # Меняем пароль
    Set-ADAccountPassword -Identity $account -NewPassword $new_password -Reset
    # Разрешаем менять пароль и ставим бесконечную длительность действия пароля
    Set-ADAccountControl -Identity $account -CannotChangePassword $false -PasswordNeverExpires $true
    Write-Host "У $account изменён пароль`n"
}