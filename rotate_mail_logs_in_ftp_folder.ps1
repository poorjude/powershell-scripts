# Определяем дату, до которой удаляем файлы (сегодня минус 1 месяц)
$monthAgo = (Get-Date).AddMonths(-1)
# Задаём директории
$targetDirs = @(
    "G:\ftp\postfix-logs",
    "G:\ftp\mailcow"
 )


foreach ($targetDir in $targetDirs) {
    # Проверяем существование целевой директории
    if (-not (Test-Path -Path $targetDir)) {
        Write-Error "ERROR: Directory $targetDir does not exist."
        continue
    }

    # Получаем список файлов и директорий старше 1 месяца и удаляем их
    Get-ChildItem -Path $targetDir | 
        Where-Object { $_.LastWriteTime -lt $monthAgo } | 
        Remove-Item -Force -Confirm:$false -Recurse

}