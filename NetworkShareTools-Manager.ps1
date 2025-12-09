param (
    [ValidateSet("Install","Uninstall")]
    [string]$Action = "Install"
)

# Config
$GitHubRepoUrl = "https://github.com/dorkfish87/NetworkShareTools"
$ModuleName = "NetworkShareTools"
$targetPath = "C:\Program Files\WindowsPowerShell\Modules\$ModuleName"

function Get-InstalledVersion {
    $manifestPath = Join-Path $targetPath "$ModuleName.psd1"
    if (Test-Path $manifestPath) {
        return (Import-PowerShellDataFile -Path $manifestPath).ModuleVersion
    }
    return $null
}

function Get-LatestVersionFromGitHub {
    $tempZip = Join-Path $env:TEMP "$ModuleName.zip"
    $downloadUrl = "$GitHubRepoUrl/archive/refs/heads/main.zip"
    Invoke-WebRequest -Uri $downloadUrl -OutFile $tempZip
    Expand-Archive -Path $tempZip -DestinationPath $env:TEMP -Force
    $extractedFolder = Get-ChildItem -Path $env:TEMP -Directory | Where-Object { $_.Name -like "$ModuleName-*" } | Select-Object -First 1
    $githubManifest = Get-ChildItem -Path $extractedFolder.FullName -Recurse -Filter "*.psd1" | Select-Object -First 1
    $latestVersion = if ($githubManifest) { (Import-PowerShellDataFile -Path $githubManifest.FullName).ModuleVersion } else { "1.0.0" }
    return @{ Version=$latestVersion; Zip=$tempZip; Folder=$extractedFolder; Manifest=$githubManifest }
}

if ($Action -eq "Uninstall") {
    Write-Host "Uninstalling module '$ModuleName'..."
    if (Test-Path $targetPath) {
        Remove-Item -Path $targetPath -Recurse -Force
        Write-Host "Module '$ModuleName' removed successfully!"
    } else {
        Write-Warning "Module '$ModuleName' is not installed."
    }
    exit
}

# Install or Update
Write-Host "Checking installed version..."
$installedVersion = Get-InstalledVersion
if ($installedVersion) { Write-Host "Installed version: $installedVersion" } else { Write-Host "Module not installed." }

Write-Host "Fetching latest version from GitHub..."
$githubData = Get-LatestVersionFromGitHub
$latestVersion = $githubData.Version
Write-Host "Latest version on GitHub: $latestVersion"

if ($installedVersion -and ([version]$installedVersion -ge [version]$latestVersion)) {
    Write-Host "Module is up-to-date. No installation needed."
    Remove-Item $githubData.Zip -Force
    Remove-Item $githubData.Folder.FullName -Recurse -Force
    exit
}

Write-Host "Installing/updating module to version $latestVersion..."
if (-not (Test-Path $targetPath)) { New-Item -ItemType Directory -Path $targetPath -Force | Out-Null }

# Copy .psm1
$psm1File = Get-ChildItem -Path $githubData.Folder.FullName -Recurse -Filter "*.psm1" | Select-Object -First 1
Copy-Item -Path $psm1File.FullName -Destination (Join-Path $targetPath "$ModuleName.psm1") -Force

# Copy or create .psd1
if ($githubData.Manifest) {
    Copy-Item -Path $githubData.Manifest.FullName -Destination (Join-Path $targetPath "$ModuleName.psd1") -Force
} else {
    New-ModuleManifest -Path (Join-Path $targetPath "$ModuleName.psd1") `
        -RootModule "$ModuleName.psm1" `
        -ModuleVersion $latestVersion `
        -Author "Your Name" `
        -Description "NetworkShareTools module for scanning network shares and reporting inaccessible files."
}

# Cleanup
Remove-Item $githubData.Zip -Force
Remove-Item $githubData.Folder.FullName -Recurse -Force

Write-Host "Module installed/updated successfully!"
Write-Host "`nYou can now run: Import-Module $ModuleName"
