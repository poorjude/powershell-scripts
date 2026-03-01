# Указываем файл .prom, в который будем писать метрики
$prom_file = "C:\Program Files\windows_exporter\textfile_inputs\subfolders_size.prom"
# Указываем директорию, для всех поддиректорий которой будет посчитан вес
$root_dir = "\\FileServer01\ShareName"

# Первично заполняем файл
Set-Content -Path $prom_file -Encoding ASCII `
    -Value "# HELP root_folder_available '1' if root folder exists, available on network and the host has read permissions, '0' otherwise"
Add-Content -Path $prom_file -Value "# TYPE root_folder_available gauge"

# Пытаемся получить список директорий
$Error.Clear()
$dirs = Get-ChildItem -Path $root_dir -Directory
if ($Error.Count -eq 0) { $bit = 1 } else { $bit = 0 }
Add-Content -Path $prom_file -Value "root_folder_available{root_folder=""$($root_dir.Replace('\', '/'))""} $bit"

# Выходим из скрипта, если корневой папки не существует/недоступна по сети/нет прав на чтение
if ($bit -eq 0) { exit 1 }

# Начинаем заполнение данных по всем директориям
Add-Content -Path $prom_file -Value "# HELP subfolder_size Size (in Gb) of subdirectories in the root folder"
Add-Content -Path $prom_file -Value "# TYPE subfolder_size gauge"

foreach ($dir in $dirs) {
    # Считаем вес
    $size = (
        (Get-ChildItem $dir.FullName -Recurse -Force | 
            Measure-Object -Sum -Property Length).Sum
    ) / 1GB
    # Округляем до двух знаков после запятой
    $size = [Math]::Round($size, 2)

    # Пишем в файл с метриками
    Add-Content -Path $prom_file -Value "subfolder_size{folder=""$($dir.FullName.Replace('\', '/'))""} $size"
}