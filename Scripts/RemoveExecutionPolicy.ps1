# Get policy
$GetExecutionPolicy = Get-ExecutionPolicy
$checkExecutionPolicy = "Undefined"

# Check if policy is Unrestricted
if(!([string]$GetExecutionPolicy -eq [string]$checkExecutionPolicy))
{
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $testadmin = $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    if ($testadmin -eq $false)
    {
        Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -noexit -file "{0}" -elevated' -f ($myinvocation.MyCommand.Definition))
        Set-ExecutionPolicy -ExecutionPolicy Undefined -Scope CurrentUser -force
        exit $LASTEXITCODE
    }
}
    start-sleep -s 1
    Write-Host "ExecutionPolicy Set to Undefined`n"