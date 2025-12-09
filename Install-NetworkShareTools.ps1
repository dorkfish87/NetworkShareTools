# Install-NetworkShareTools.ps1
$GitHubRepoUrl = "https://github.com/dorkfish87/NetworkShareTools"
$ModuleName = "NetworkShareTools"
$targetPath = "C:\Program Files\WindowsPowerShell\Modules\$ModuleName"

Write-Host "Checking installed version..."
$installedVersion = $null
$manifestPath = Join-Path $targetPath "$ModuleName.psd1"
if (Test-Path $manifestPath) {
    $installedVersion = (Import-PowerShellDataFile -Path $manifestPath).ModuleVersion
    Write-Host "Installed version: $installedVersion"
}

Write-Host "Fetching latest version from GitHub..."
$tempZip = Join-Path $env:TEMP "$ModuleName.zip"
$downloadUrl = "$GitHubRepoUrl/archive/refs/heads/main.zip"
Invoke-WebRequest -Uri $downloadUrl -OutFile $tempZip

Expand-Archive -Path $tempZip -DestinationPath $env:TEMP -Force
$extractedFolder = Get-ChildItem -Path $env:TEMP -Directory | Where-Object { $_.Name -like "$ModuleName-*" } | Select-Object -First 1

# Check version in GitHub manifest
$githubManifest = Get-ChildItem -Path $extractedFolder.FullName -Recurse -Filter "*.psd1" | Select-Object -First 1
$latestVersion = if ($githubManifest) { (Import-PowerShellDataFile -Path $githubManifest.FullName).ModuleVersion } else { "1.0.0" }
Write-Host "Latest version on GitHub: $latestVersion"

# Compare versions
if ($installedVersion -and ([version]$installedVersion -ge [version]$latestVersion)) {
    Write-Host "Module is up-to-date. No installation needed."
    Remove-Item $tempZip -Force
    Remove-Item $extractedFolder.FullName -Recurse -Force
    exit
}

Write-Host "Installing/updating module to version $latestVersion..."
if (-not (Test-Path $targetPath)) { New-Item -ItemType Directory -Path $targetPath -Force | Out-Null }

# Copy .psm1 and .psd1
$psm1File = Get-ChildItem -Path $extractedFolder.FullName -Recurse -Filter "*.psm1" | Select-Object -First 1
Copy-Item -Path $psm1File.FullName -Destination (Join-Path $targetPath "$ModuleName.psm1") -Force

if ($githubManifest) {
    Copy-Item -Path $githubManifest.FullName -Destination (Join-Path $targetPath "$ModuleName.psd1") -Force
} else {
    New-ModuleManifest -Path (Join-Path $targetPath "$ModuleName.psd1") `
        -RootModule "$ModuleName.psm1" `
        -ModuleVersion $latestVersion `
        -Author "Your Name" `
        -Description "NetworkShareTools module for scanning network shares and reporting inaccessible files."
}

# Cleanup
Remove-Item $tempZip -Force
Remove-Item $extractedFolder.FullName -Recurse -Force

Write-Host "Module installed/updated successfully!"
