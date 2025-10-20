# Загружаем список файлов
$files_list = (Get-Content -Path ".\check_files_and_tasks_input_files.txt")

Write-Host "Files check started" -BackgroundColor Green
foreach ($path in $files_list) {
    if (Test-Path $path) {
        Write-Host ($path)
        # Remove-Item -Path $path -Force
    }
}
Write-Host "Files check ended" -BackgroundColor Green



# Загружаем список задач
$tasks_list = (Get-Content -Path ".\check_files_and_tasks_input_tasks.txt")
# Получаем список всех задач на ПК
$allScheduledTasks = Get-ScheduledTask

Write-Host "Task scheduler check started" -BackgroundColor Green
# Проходимся по каждой задаче из списка
foreach ($taskName in $tasks_list) {
    # Проходимся по каждой задаче на ПК
    foreach ($task in $allScheduledTasks) {
        if ($task.TaskName -like $taskName) { # -and $task.State -ne "Disabled"
            Write-Host ($task)
            # Останавливаем и дизейблим задачу
            Stop-ScheduledTask -TaskName $taskName
            Disable-ScheduledTask -TaskName $taskName
            # Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        }
    }
}
Write-Host "Task scheduler check ended" -BackgroundColor Green