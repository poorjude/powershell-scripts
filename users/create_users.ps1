# Генерирует рандомный пароль с задаваемой длиной
function Generate-RandomPassword {
    param ([int]$Length)

    $chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789{}[]!@#$%^&*()_+-='.ToCharArray()
    $password = -join (Get-Random -InputObject $chars -Count $Length)
    return $password
}

$inputFile = '.\create_users_input.txt'
$outputFile = '.\create_users_result.txt'
$outputErrorFile = '.\create_users_errors.txt'

$inputData = Get-Content $inputFile

$Error.Clear()
foreach ($name in $inputData) {
    # Генерируем пароль
    $pass = ConvertTo-SecureString (Generate-RandomPassword -Length 20) -AsPlainText -Force
    # Добавляем пользователя
    New-LocalUser -Name $name -Password $pass -PasswordNeverExpires -UserMayNotChangePassword

    # Проверяем на ошибки и пишем результат в логи
    if ($Error.Count -eq 0) {
        Add-Content -Path $outputFile -Value $name
        Add-Content -Path $outputFile -Value $passRaw
        Add-Content -Path $outputFile -Value ""
    } else {
        Add-Content -Path $outputErrorFile -Value "ОШИБКА во время добавления УЗ $name"
        Add-Content -Path $outputErrorFile -Value $Error
        Add-Content -Path $outputErrorFile -Value ""
        $Error.Clear()
    }
}