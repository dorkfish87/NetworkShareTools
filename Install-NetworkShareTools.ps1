# Hardcoded GitHub repository URL
$GitHubRepoUrl = "https://github.com/dorkfish87/NetworkShareTools"
$ModuleName = "NetworkShareTools"

# Target module path (system-wide)
$targetPath = "C:\Program Files\WindowsPowerShell\Modules\$ModuleName"

Write-Host "Installing module '$ModuleName' from GitHub to $targetPath..."

# Ensure script runs as Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "You must run this script as Administrator to install to Program Files."
    exit
}

# Create target directory if it doesn't exist
if (-not (Test-Path $targetPath)) {
    New-Item -ItemType Directory -Path $targetPath -Force | Out-Null
}

# Download ZIP from GitHub
$tempZip = Join-Path $env:TEMP "$ModuleName.zip"
$downloadUrl = "$GitHubRepoUrl/archive/refs/heads/main.zip"

Write-Host "Downloading module from $downloadUrl..."
Invoke-WebRequest -Uri $downloadUrl -OutFile $tempZip

# Extract ZIP
Write-Host "Extracting module files..."
Expand-Archive -Path $tempZip -DestinationPath $env:TEMP -Force

# Find extracted folder (usually ends with '-main')
$extractedFolder = Get-ChildItem -Path $env:TEMP -Directory | Where-Object { $_.Name -like "$ModuleName-*" } | Select-Object -First 1

if (-not $extractedFolder) {
    Write-Warning "Could not find extracted module folder. Check GitHub URL."
    exit
}

# Search for .psm1 file recursively
$psm1File = Get-ChildItem -Path $extractedFolder.FullName -Recurse -Filter "*.psm1" | Select-Object -First 1
if (-not $psm1File) {
    Write-Warning "Module file (.psm1) not found anywhere in the repo. Installation cannot proceed."
    exit
}

# Copy and rename .psm1 to match module name
Copy-Item -Path $psm1File.FullName -Destination (Join-Path $targetPath "$ModuleName.psm1") -Force

# Check for .psd1 file
$psd1File = Get-ChildItem -Path $extractedFolder.FullName -Recurse -Filter "*.psd1" | Select-Object -First 1
if ($psd1File) {
    Copy-Item -Path $psd1File.FullName -Destination (Join-Path $targetPath "$ModuleName.psd1") -Force
} else {
    Write-Host "Creating module manifest (.psd1)..."
    New-ModuleManifest -Path (Join-Path $targetPath "$ModuleName.psd1") `
        -RootModule "$ModuleName.psm1" `
        -ModuleVersion "1.0.0" `
        -Author "Your Name" `
        -Description "NetworkShareTools module for scanning network shares and reporting inaccessible files."
}

# Clean up temp files
Remove-Item $tempZip -Force
Remove-Item $extractedFolder.FullName -Recurse -Force

# Validate installation
Write-Host "Validating module installation..."
if (Test-Path (Join-Path $targetPath "$ModuleName.psm1")) {
    Write-Host "`nModule '$ModuleName' installed successfully!"
    Write-Host "You can now run:"
    Write-Host "Import-Module $ModuleName`n"
} else {
    Write-Warning "Module installation failed. .psm1 file missing in final location."
}
