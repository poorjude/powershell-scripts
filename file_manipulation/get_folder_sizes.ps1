# Загружаем список папок
$folder_list = Get-Content -Path ".\get_folder_sizes_input.txt" -Encoding utf8

# Указываем имя файла, в который будем класть результаты
$folder_sizes = ".\get_folder_sizes_output.txt"

$Error.Clear()
foreach ($folder in $folder_list) {
    # Считаем размер для текущей папки в гигабайтах
    $curr_size = (
        (Get-ChildItem $folder -Recurse -Force | 
            Measure-Object -Sum -Property Length).Sum
    ) / 1GB
    # Округляем до двух знаков после запятой
    $curr_size = [Math]::Round($curr_size, 2)
    # Меняем "." на "," в дроби
    $curr_size = $curr_size.ToString().Replace(".", ",")

    # Если поймали ошибку - указываём её вместо размера папки
    if ($Error.Count -gt 0) {
        # Пишем результат в консоль
        Write-Host ($folder + ": ОШИБКА - " + $Error[0].Exception.Message)
        # Пишем результат в файл
        Add-Content -Path $folder_sizes -Value ($folder + ";ОШИБКА - " + $Error[0].Exception.Message)

        $Error.Clear()
    } else {
        # Пишем результат в консоль
        Write-Host ($folder + ": " + $curr_size)
        # Пишем результат в файл
        Add-Content -Path $folder_sizes -Value ($folder + ";" + $curr_size)
    }
}