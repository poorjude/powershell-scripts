Import-Module ActiveDirectory

# Здесь задаём фильтры, по которым отбираем нужные аккаунты
$AD_users = Get-ADUser -Properties * -Filter { 
    (SamAccountName -like "Moscow_User*") -and 
    (SamAccountName -notlike "Moscow_User_test*") -and 
    (SamAccountName -notlike "Moscow_User_00test*") 
}
# Указываем целевую группу для всех аккаунтов
$targetGroup = "Moscow_Users"
# Указываем целевую OU для всех аккаунтов (в нотации LDAP)
$targetOU = "OU=Moscow,OU=Users,DC=test,DC=domain,DC=local"



# Проверяем, что УЗ лежит в нужном OU
$AD_users | 
    Where-Object { $_.DistinguishedName -notlike "*,$targetOU" } | 
        Select-Object SamAccountName, DistinguishedName |
            Format-Table -AutoSize

# Проверяем, что УЗ принадлежит нужной группе
$AD_users | 
    Where-Object { $_.MemberOf -notlike "*$targetGroup*" } | 
        Select-Object SamAccountName, MemberOf |
            Format-Table -AutoSize

# Проверяем, что УЗ включена
$AD_users | 
    Where-Object { $_.Enabled -ne $true } | 
        Select-Object SamAccountName, Enabled |
            Format-Table -AutoSize

# Проверяем, что УЗ не заблокирована
$AD_users | 
    Where-Object { $_.LockedOut -ne $false } | 
        Select-Object SamAccountName, LockedOut |
            Format-Table -AutoSize

# Проверяем, что пароль УЗ действует бессрочно
$AD_users | 
    Where-Object { $_.PasswordNeverExpires -ne $true } | 
        Select-Object SamAccountName, PasswordNeverExpires |
            Format-Table -AutoSize

# Проверяем, что пароль от УЗ подходит (Аккуратно! Несколько попыток ввода неправильного пароля могут блокировать УЗ)
$credential = Get-Credential -UserName "123" -Message "Enter password only"
[System.Reflection.Assembly]::LoadWithPartialName("System.DirectoryServices.AccountManagement") | Out-Null
$principal_context = New-Object System.DirectoryServices.AccountManagement.PrincipalContext([System.DirectoryServices.AccountManagement.ContextType]::Domain, "hq.icfed.com")
foreach ($AD_user in $AD_users) {
    $isValid = $principal_context.ValidateCredentials($AD_user.SamAccountName, $credential.GetNetworkCredential().password)
    if (-not $isValid) {
        Write-Host "Authentication failed for the user: $($AD_user.SamAccountName)"
    }
}