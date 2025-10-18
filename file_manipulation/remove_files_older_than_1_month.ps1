# Определяем дату, до которой удаляем файлы (сегодня минус 1 месяц)
$monthAgo = (Get-Date).AddMonths(-1)
# Задаём директорию
$directory = "D:\Files"

# Проверяем существование целевой директории
if (-not (Test-Path -Path $directory -PathType Container)) {
    Write-Error "Ошибка: Директория '$directory' не существует."
    exit 1
}

# Получаем список файлов старше 1 месяца и удаляем их
Get-ChildItem -Path $directory -File | 
    Where-Object { $_.LastWriteTime -lt $monthAgo } | 
    Remove-Item -Force -Confirm:$false