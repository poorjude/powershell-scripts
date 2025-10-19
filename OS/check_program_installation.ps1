$hosts = @(
    "ServerName01"
    "ServerName02"
    "ServerName03"
)

$resultPath = ".\check_program_installation_result.txt"
$errorsPath = ".\check_program_installation_errors.txt"

$targetProgramVersion = "19.3.1"
$programVersionRegPath = "HKLM:\SOFTWARE\Company\ProgramName\CurrentVersion\"
$programFolderPath = "C:\Program Files\Company\ProgramName\$targetProgramVersion"

$Error.Clear()
foreach ($currHost in $hosts) {
    $invComRes = Invoke-Command -ComputerName $currHost -ScriptBlock { 
        (Test-Path -Path $programFolderPath) -and 
        ((Get-ItemProperty $programVersionRegPath).ProgramVersion -eq $targetProgramVersion) 
    }

    if ($Error.Count -gt 0) {
        "ERROR: $currHost"
        Add-Content -Path $errorsPath -Value $currHost
        $Error.Clear()
    } elseif($invComRes) {
        "The program is installed: $currHost"
    } else {
        "The program is NOT installed: $currHost"
        Add-Content -Path $resultPath -Value $currHost
    }
}