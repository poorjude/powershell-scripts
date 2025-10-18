Import-Module Hyper-V

# Указываем имена ВМ, которые будут перемещены
$vms = @(
    "VM01"
    "VM02"
    "VM03"
)
# Указываем гипервизор-реципиент
$destHost = "ServerName02"
# Указываем папку назначения
$destPath = "D:\Hyper-V"

$Error.Clear()
foreach ($vm in $vms) {
    # Перемещаем ВМ
    Move-VM -Name $vm -DestinationHost $destHost -IncludeStorage -DestinationStoragePath $destPath
    if ($Error.Count -gt 0) { break }
    "ВМ $vm была перемещена на хост $destHost"

    # Проверяем доступность ВМ по сети
    Start-Sleep -Seconds 3
    if (Test-Connection -ComputerName $vm -Count 5 -Quiet) {
        "ВМ $vm доступна по сети после миграции"
    } else {
        Write-Host "ВМ $vm НЕДОСТУПНА по сети после миграции!" -BackgroundColor Red
    }
}