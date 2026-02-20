# Задаём названия групп
$adGroupToLogoff = "Domain Admins"
$localGroupToLogoff = "Administrators"

# Получаем пользователей
$usersToLogoff = 
    (Get-ADGroupMember -Identity $adGroupToLogoff | Where-Object { $_.objectClass -eq 'user' }).Name + 
    (Get-LocalGroupMember $localGroupToLogoff | Where-Object { $_.objectClass -eq 'user' }).Name

$sessionData = @()

# Получаем список сессий
qwinsta | 
Select-Object -Skip 1 | # Пропускаем заголовок
ForEach-Object { 
    $splittedStr = ($_.Replace('>', ' ') -split '\s+') | # Разбиваем строку на массив из подстрок
        Where-Object { $_ -notmatch '^\s*$' } # Отбрасываем пустые строки
    
    # Если сессия запущена от пользователя, то у нее будет минимум 4 непустых поля, и Username будет во 2-м
    if ($splittedStr.Count -ge 4) { 
        $username = $splittedStr[1] 
    } else { 
        $username = "" 
    }

    # ID - первая не пустая строка, содержащая целое положительное число
    $id = $splittedStr | Where-Object { $_ -match '^\d+$' } | Select-Object -First 1 

    $sessionData += [PSCustomObject]@{ Username = $username; Id = $id }
}

# Завершаем сессии
foreach ($session in $sessionData) {
    if ($session.Username -in $usersToLogoff) {
        "$($session.Username) will be kicked"
        logoff $session.Id
    }
}