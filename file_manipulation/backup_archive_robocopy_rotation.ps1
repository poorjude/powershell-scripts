# Задаем переменные
$sourceDir = "C:\Program Files\MyProgram\BackupedFolder"

$tempFolder = "C:\tmp"
$tempArchive = Join-Path $tempFolder "backup_$(Get-Date -Format 'yyyyMMdd').zip"

$targetShare = "\\BackupServer01.domain.local\BackupsDir01"
$finalArchive = Join-Path "$targetShare" "backup_$(Get-Date -Format 'yyyyMMdd').zip"

$logFolder = "C:\Logs"
$logFile = Join-Path "$logFolder" "backup.log"

# Задаём продолжительность хранения и количество хранимых копий
$backupedCopiesDurationDays = 13
$backupedCopiesAmount = 2



# Создаем папки и файлы
if (-not (Test-Path $tempFolder)) {
    New-Item -Path $tempFolder -ItemType Directory
}
if (-not (Test-Path $logFolder)) {
    New-Item -Path $logFolder -ItemType Directory
}
if (-not (Test-Path $logFile)) {
    New-Item -Path $logFile -ItemType File -Value "" -Encoding UTF8
}

# Создание архива
Compress-Archive -Path $sourceDir -DestinationPath $tempArchive -Force -CompressionLevel Fastest -Verbose | 
    Out-File $logFile -Append -Encoding UTF8

# Перемещение (!) архива на сетевую папку через robocopy
robocopy "$(Split-Path $tempArchive)\." "$(Split-Path $finalArchive)\" "$(Split-Path $tempArchive -Leaf)" `
/MOV /R:2 /W:1 /NP 2>&1 | Out-File $logFile -Append -Encoding UTF8

# Логирование результата
if ($LASTEXITCODE -lt 8) {
    "Success: $(Get-Date)" | Out-File $logFile -Append -Encoding UTF8
} else {
    "Error (code $LASTEXITCODE): $(Get-Date)" | Out-File $logFile -Append
    exit $LASTEXITCODE # Выходим из скрипта, если бэкапирование завершилось с ошибкой
}



# Очистка старых архивов (запускается, только если бэкапирование было успешно завершено)
$currentBackupCopies = Get-ChildItem $targetShare -Filter *.zip
if ($currentBackupCopies.Count -gt $backupedCopiesAmount) {
    $currentBackupCopies | 
        Where LastWriteTime -lt (Get-Date).AddDays(-$backupedCopiesDurationDays) | 
        Remove-Item -Force
}