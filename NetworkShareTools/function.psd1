@{
    # Script module or binary module file associated with this manifest
    RootModule = 'NetworkShareTools.psm1'

    # Version number of this module
    ModuleVersion = '1.0.4'

    # ID used to uniquely identify this module
    GUID = '9c663cc5-8bd4-4d4e-95b0-edef32ed4d0c'  # Use New-Guid to generate

    # Author of this module
    Author = 'Cody Frazier'

    # Copyright statement for this module
    Copyright = '(c) 2025 Your Company. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'Provides tools to scan network shares for inaccessible files and folders, with detailed reporting.'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.0'

    # Functions to export from this module
    FunctionsToExport = @('Get-NetworkShareAccessReport')

    # Cmdlets to export from this module
    CmdletsToExport = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module
    AliasesToExport = @()

    # Private data to pass to the module
    PrivateData = @{

        PSData = @{
            # Tags applied to this module for searching
            Tags = @('NetworkShare', 'AccessReport', 'FileAudit')

            # A URL to the license for this module
            LicenseUri = 'https://opensource.org/licenses/MIT'

            # A URL to the main website for this project
            ProjectUri = 'https://github.com/dorkfish87/NetworkShareTools'

            # A URL to an icon representing this module
            IconUri = ''

            # Release notes for this module
            ReleaseNotes = 'Initial release with multi-threaded scanning, CSV output, and folder summary.'
        }
    }
}
