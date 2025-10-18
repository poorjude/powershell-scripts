Import-Module Hyper-V

$hvs = @(
    "servername01"
    "servername02"
    "servername03"
)

foreach ($hv in $hvs) {
    "ВМ на гипервизоре '$hv':"
    Invoke-Command -ComputerName $hv -ScriptBlock { 
        Get-VM | ForEach-Object { $_.Name }
        # Get-VM | Where-Object { $_.State -eq "Running" } | ForEach-Object { $_.Name }
        # Get-VM | Where-Object { $_.State -eq "Running" } | ForEach-Object { '"' + $_.Name + '"' }
        # Get-VM | Where-Object { $_.Name -notlike "*test*" -or $_.Name -notlike "*dev*" } | ForEach-Object { $_.Name }
    }
    ""
}