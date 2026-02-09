<# 
    Скрипт решает следующие задачи: 
    1) отобрать пользователей, у которых сейчас назначена хоть какая-нибудь домашняя директория (Home Directory)
    2) очистить домашние директории для тех пользователей, логин которых начинается с "test" или заканчивается на "test"
    *(Для оставшихся/нетестовых пользователей:)*
    3) заново отобрать пользователей, у которых сейчас назначена хоть какая-нибудь домашняя директория
    4) унифицировать домашние директории оставшихся пользователей до вида '\\FileServer01\HomeDir_root\<SamAccountName>', 
       где SamAccountName - собственно, логин пользователя
    5) если домашней директории не существует, то создать её и назначить нужные права (FullControl для пользователя)
    6) если домашняя директория существует, то проверить, назначены ли ей нужные права (FullControl для пользователя)

    Скрипт должен запускаться от УЗ с правами Account Operator в домене и с правами FullControl на сетевой папке,
    в которой будут создаваться домашние директории пользователей.
#>

$rootShare = '\\FileServer01\HomeDir_root'

### I. Очищаем домашние директории для тестовых аккаунтов

# Отбираем включенные тестовые аккаунты "test*" или "*test" с не пустой домашней директорией
$adUsersWithHomeFolderToClear = Get-ADUser -Properties * -Filter { 
    (Enabled -eq $true) -and
    (HomeDirectory -like '*') -and
    (SamAccountName -like "test*" -or SamAccountName -like "*test")
}
# Очищаем HomeDirectory для каждой УЗ
foreach ($adUser in $adUsersWithHomeFolderToClear) {
    Set-ADUser $adUser -Clear HomeDirectory
}
# Выводим в консоль
"Accounts with removed HomeDirectory"
$adUsersWithHomeFolderToClear | Select-Object SamAccountName, HomeDirectory
"Total: " + $adUsersWithHomeFolderToClear.Count



### II. Унифицируем домашние директории для пользовательских аккаунтов

# Отбираем включенные аккаунты с неправильно указанной домашней директорией
$adUsersWithIncorrectHomeFolder = 
    Get-ADUser -Properties * -Filter { (Enabled -eq $true) -and (HomeDirectory -like '*') } | 
    Where-Object { $_.HomeDirectory -notlike (Join-Path $rootShare $_.SamAccountName) }
# Ставим правильную директорию
foreach ($adUser in $adUsersWithIncorrectHomeFolder) {
    Set-ADUser $adUser -HomeDirectory (Join-Path $rootShare $adUser.SamAccountName)
}
# Выводим в консоль
"Accounts with fixed HomeDirectory"
$adUsersWithHomeFolderToClear | Select-Object SamAccountName, HomeDirectory
"Total: " + $adUsersWithHomeFolderToClear.Count



### III. Создаём домашние директории для пользовательских аккаунтов в сетевой папке

# Отбираем: включенные учетки с правильно указанной домашней директорией
$adUsers = 
    Get-ADUser -Properties * -Filter { (Enabled -eq $true) -and (HomeDirectory -like '*') } | 
    Where-Object { $_.HomeDirectory -like (Join-Path $rootShare $_.SamAccountName) }

foreach ($adUser in $adUsers) {
    $homeDir = $adUser.HomeDirectory
    $username = $adUser.SamAccountName

    # Если не существует, создаём директорию
    if (-not (Test-Path $homeDir)) {
        New-Item -Path $homeDir -ItemType Directory
    }

    # Получаем текущие права с директории
    $homeDirAcl = Get-Acl -Path $homeDir

    # Проверяем, существуют ли нужные нам права
    $permissionForUserExists = $homeDirAcl | Select-Object -ExpandProperty Access | 
        Where-Object { 
            ($_.FileSystemRights -eq "FullControl") -and
            ($_.AccessControlType -eq "Allow") -and 
            ($_.IdentityReference -like "DOMAIN\$username") -and
            ($_.InheritanceFlags -eq "ContainerInherit", "ObjectInherit") -and
            ($_.PropagationFlags -eq "None")
        }
    
    if ($permissionForUserExists -eq $null) {
        # Если не существуют, добавляем правило в ACL и назначаем на папку
        $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            "DOMAIN\$username", 
            "FullControl", 
            "ContainerInherit,ObjectInherit", 
            "None", 
            "Allow"
        )
        $homeDirAcl.SetAccessRule($accessRule)
        Set-Acl -Path $homeDir -AclObject $homeDirAcl
    }
}
