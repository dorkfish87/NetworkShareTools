param (
    [Parameter(Mandatory=$true)]
    [string]$GitHubRepoUrl = "https://github.com/dorkfish87/NetworkShareTools"
    [string]$ModuleName = "NetworkShareTools"
)

# Target module path
$targetPath = Join-Path $env:USERPROFILE "Documents\PowerShell\Modules\$ModuleName"

Write-Host "Installing module '$ModuleName' from GitHub to $targetPath..."

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

# Copy files to module path
Copy-Item -Path (Join-Path $extractedFolder.FullName "*") -Destination $targetPath -Recurse -Force

# Clean up
Remove-Item $tempZip -Force
Remove-Item $extractedFolder.FullName -Recurse -Force

Write-Host "Module installed successfully!"

# Verify installation
if (Get-Module -ListAvailable $ModuleName) {
    Write-Host "`nModule '$ModuleName' is now available. Import it using:"
    Write-Host "Import-Module $ModuleName`n"
} else {
    Write-Warning "Module installation failed. Please check the GitHub URL and try again."
}
