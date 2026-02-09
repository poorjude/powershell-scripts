function Generate-RandomPassword {
    param ([int]$Length)

    $chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789{}[]!@#$%^&*()_+-='.ToCharArray()
    $password = -join (Get-Random -InputObject $chars -Count $Length)
    return $password
}



$inputFile = "create_ad_users_input.csv"

# Указываем, в какую OU будут помещены пользователи
$OU = "OU=Moscow,OU=Russia,DC=domain,DC=local"
# Указываем, в какую группу будут добавлены пользователи
$group = "MoscowStaff"



$data = Import-Csv -Path $inputFile -Delimiter ";" -Encoding Default

foreach ($userData in $data) {
    $passwordRaw = (Generate-RandomPassword -Length 16)
    $password = ConvertTo-SecureString $passwordRaw -AsPlainText -Force

    $Error.Clear()

    New-ADUser `
        -Name ($userData.Surname + " " + $userData.Name) `
        -GivenName $userData.Name `
        -Surname $userData.Surname `
        -SamAccountName $userData.SamAccountName `
        -Path $OU `
        -AccountPassword $password `
        -Enabled $true `
        -ChangePasswordAtLogon $false

    Add-ADGroupMember -Identity $group -Members $userData.SamAccountName

    if ($Error.Count -gt 0) {
        "При создании следующего пользователя возникла ошибка:"
    } else {
        "Следующий пользователь был успешно добавлен:"
    }

    # Выводим логин созданного пользователя вместе с паролем (!)
    $userData.SamAccountName + " $passwordRaw" 
}