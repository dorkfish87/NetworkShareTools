# Uninstall-NetworkShareTools.ps1
$ModuleName = "NetworkShareTools"
$targetPath = "C:\Program Files\WindowsPowerShell\Modules\$ModuleName"

Write-Host "Uninstalling module '$ModuleName' from $targetPath..."

if (Test-Path $targetPath) {
    Remove-Item -Path $targetPath -Recurse -Force
    Write-Host "Module '$ModuleName' removed successfully!"
} else {
    Write-Warning "Module '$ModuleName' is not installed in $targetPath."
}
