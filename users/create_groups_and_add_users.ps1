$inputFile = '.\create_groups_and_add_users_input.txt'
$outputFile = '.\create_groups_and_add_users_result.txt'
$outputErrorFile = '.\create_groups_and_add_users_errors.txt'

$inputData = Get-Content $inputFile -Encoding UTF8

for($i = 0; $i -lt $inputData.count) {
    $Error.Clear()
    $currStr = $inputData[$i]
    # Начинаем новую группу
    if ($currStr -like "Члены группы *") {
        $groupName = $currStr.Substring(13)
        $i++
        $currStr = $inputData[$i]
        $comment = $currStr.Substring(15)
        Set-LocalGroup -Name $groupName -Description $comment
        if ($Error.Count -eq 0) {
            Add-Content -Path $outputFile -Value "Добавлено описание в группу $groupName"
        } else {
            Add-Content -Path $outputErrorFile -Value "ОШИБКА во время добавления описания в группу $groupName"
            Add-Content -Path $outputErrorFile -Value $Error
        }
    }
    # ...Или добавляем пользователей в уже созданную группу
    else {
        Add-LocalGroupMember -Group $groupName -Member $currStr
        if ($Error.Count -eq 0) {
            Add-Content -Path $outputFile -Value "Пользователь $currStr добавлен в группу $groupName"
        } else {
            Add-Content -Path $outputErrorFile -Value "ОШИБКА во время добавления пользователя $currStr в группу $groupName"
            Add-Content -Path $outputErrorFile -Value $Error
        }
    }
    $i++
}