# Указываем гипервизоры, с которых будем бекапить ВМ
$hvs = @(
    "servername01"
    "servername02"
    "servername03"
)
# Указываем сетевую папку, на которую будем класть бекапы
$networkPath = "\\BackupNode\BackupShare"
# Указываем локальную папку для экспорта ВМ на каждом из гипервизоров
$localExport = "D:\Export"
# Вводим логин-пароль для подключения к сетевой папке
$credential = Get-Credential -Message "Enter the credentials for the network share $networkPath"

foreach ($hv in $hvs) {
    Write-Host "НАЧИНАЕМ БЕКАП ГИПЕРВИЗОРА $hv" -BackgroundColor Green

    Invoke-Command -ComputerName $hv -ScriptBlock { 
        # Получаем список названий ВМ
        $vms = Get-VM | 
            Where-Object { $_.Name -notlike "*test*" } | # Отсеиваем ненужные ВМ по имени
            ForEach-Object { $_.Name }

        # Создаём папку, если её нет
        if (!(Test-Path $localExport)) {
            New-Item -ItemType Directory -Path $localExport | Out-Null
        }

        # Подключаем сетевой диск
        New-PSDrive -Name "Z" -PSProvider FileSystem -Root $networkPath -Credential $credential -Persist

        foreach ($vm in $vms) {
            $vmExportPath = Join-Path $localExport $vm

            Write-Host "Экспортирую ВМ: $vm в $vmExportPath..."
            Export-VM -Name $vm -Path $vmExportPath -CaptureLiveState CaptureDataConsistentState

            Write-Host "Экспорт завершён. Копирую на сетевую папку..."
            Copy-Item -Path $vmExportPath -Destination "Z:\" -Recurse -Force

            Write-Host "Удаляю локальную копию $vm..."
            Remove-Item -Path $vmExportPath -Recurse -Force

            Write-Host "ВМ $vm успешно скопирована"
        }

        # Отключаем диск
        Write-Host "Отключаю диск Z"
        Remove-PSDrive -Name "Z"
    }

    Write-Host "ЗАВЕРШЁН БЕКАП ГИПЕРВИЗОРА $hv" -BackgroundColor Green
}