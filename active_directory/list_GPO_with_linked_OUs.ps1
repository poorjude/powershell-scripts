Import-Module ActiveDirectory

# Вводим домен
$domain = Read-Host -Prompt "Введите домен"
# Получаем все GPO
$allGPOs = Get-GPO -All -Domain $domain
# Получаем все OU (включая "корневую", т.е. сам домен)
$allOUs = (Get-ADDomain -Server $domain) + (Get-ADOrganizationalUnit -Filter * -Server $domain) | 
    Where-Object { $_.LinkedGroupPolicyObjects } # убираем OU без привязанных политик



$result = @()
# Начинаем цикл для каждой политики
foreach ($GPO in $allGPOs) {
    $curr_result = [PSCustomObject]@{
        "Имя" = $GPO.DisplayName
        "Статус" = if ($GPO.GpoStatus -eq "AllSettingsDisabled") { "Отключена" } else { "Включена" }
        "Привязанные OU"  = @()
    }
    
    # Начинаем цикл для каждой OU
    foreach ($OU in $allOUs) {
        # Начинаем цикл для каждой ссылки на политику в OU
        foreach($OU_GPLink in $OU.LinkedGroupPolicyObjects) {
            if ($OU_GPLink -match $GPO.Id) { 
                $curr_result."Привязанные OU" += $OU.Name
                break
            }
        }
    }

    $result += $curr_result
}
$result = $result | Sort-Object "Имя"

# Выводим на консоль
$result
"`nПолитик всего: " + $result.Count

# Пишем в файл
$result_file_path = ".\list_GPO_with_linked_OUs_output.txt"

Add-Content -Path $result_file_path -Value "Имя;Статус;Привязанные OU" -Encoding UTF8
foreach ($curr_result in $result) {
    Add-Content -Path $result_file_path -Encoding UTF8 -Value ( `
        $curr_result."Имя" + ";" + `
        $curr_result."Статус" + ";" + `
        ($curr_result."Привязанные OU" -join ', ') `
    )
}
Add-Content -Path $result_file_path -Value "`n`n`n" -Encoding UTF8
"`nРезультаты записаны в файл: $result_file_path"