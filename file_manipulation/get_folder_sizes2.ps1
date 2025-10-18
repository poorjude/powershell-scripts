# Указываем директорию, для всех поддиректорий которой будет посчитан вес
$dirs = Get-ChildItem -Path "D:\Files" -Directory 

$dirs_and_sizes = @()

foreach ($dir in $dirs) {
    $curr_size = (
        (Get-ChildItem $dir.FullName -Recurse -Force | 
            Measure-Object -Sum -Property Length).Sum
    ) / 1GB

    $curr_size = [Math]::Round($curr_size, 2)

    $dirs_and_sizes += [PSCustomObject]@{
        Folder = $dir.FullName
        Size_in_Gb = $curr_size
    }
}

$dirs_and_sizes | Format-Table