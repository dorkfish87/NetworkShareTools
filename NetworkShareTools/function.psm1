function Get-NetworkShareAccessReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$NetworkShare,

        [Parameter(Mandatory=$true)]
        [string]$OutputCSV,

        [Parameter(Mandatory=$true)]
        [string]$SummaryCSV,

        [int]$ThrottleLimit = 10
    )

    # Initialize CSV files
    "Path,ErrorMessage,Timestamp,Size(Bytes),Owner" | Out-File $OutputCSV
    "Folder,InaccessibleCount" | Out-File $SummaryCSV

    # Get all items
    $items = Get-ChildItem -Path $NetworkShare -Recurse -ErrorAction SilentlyContinue
    $total = $items.Count
    $count = 0

    # Folder summary storage
    if ($PSVersionTable.PSVersion.Major -ge 7) {
        # PowerShell 7+ (Parallel)
        $folderSummary = [System.Collections.Concurrent.ConcurrentDictionary[string,int]]::new()

        $items | ForEach-Object -Parallel {
            param($OutputCSV, $folderSummary, $total)

            try {
                $obj = Get-Item $_.FullName
                $size = if ($obj.PSIsContainer) { 0 } else { $obj.Length }
                $owner = (Get-Acl $obj.FullName).Owner
            }
            catch {
                $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                $errorMsg = $_.Exception.Message.Replace("`n"," ").Replace("`r"," ")
                $size = if ($_.PSIsContainer) { 0 } else { $_.Length }
                $owner = "Unknown"

                "$($_.FullName),$errorMsg,$timestamp,$size,$owner" | Out-File -Append -FilePath $OutputCSV

                $folder = Split-Path $_.FullName -Parent
                $folderSummary.AddOrUpdate($folder, 1, { param($key,$old) $old + 1 })
            }

            [System.Threading.Interlocked]::Increment([ref]$using:count) | Out-Null
            $percent = [math]::Round(($using:count / $total) * 100, 2)
            Write-Progress -Activity "Scanning Network Share" -Status "$percent% Complete" -PercentComplete $percent

        } -ArgumentList $OutputCSV, $folderSummary, $total -ThrottleLimit $ThrottleLimit

        # Export folder summary
        $folderSummary.GetEnumerator() | ForEach-Object {
            "$($_.Key),$($_.Value)" | Out-File -Append -FilePath $SummaryCSV
        }
    }
    else {
        # Windows PowerShell 5.1 (Sequential)
        $folderSummary = @{}

        foreach ($item in $items) {
            try {
                $obj = Get-Item $item.FullName
                $size = if ($obj.PSIsContainer) { 0 } else { $obj.Length }
                $owner = (Get-Acl $obj.FullName).Owner
            }
            catch {
                $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                $errorMsg = $_.Exception.Message.Replace("`n"," ").Replace("`r"," ")
                $size = if ($item.PSIsContainer) { 0 } else { $item.Length }
                $owner = "Unknown"

                "$($item.FullName),$errorMsg,$timestamp,$size,$owner" | Out-File -Append -FilePath $OutputCSV

                $folder = Split-Path $item.FullName -Parent
                if ($folderSummary.ContainsKey($folder)) {
                    $folderSummary[$folder]++
                } else {
                    $folderSummary[$folder] = 1
                }
            }

            $count++
            $percent = [math]::Round(($count / $total) * 100, 2)
            Write-Progress -Activity "Scanning Network Share" -Status "$percent% Complete" -PercentComplete $percent
        }

        # Export folder summary
        foreach ($folder in $folderSummary.Keys) {
            "$folder,$($folderSummary[$folder])" | Out-File -Append -FilePath $SummaryCSV
        }
    }

    Write-Host "Scan complete. Detailed results saved to $OutputCSV and folder summary to $SummaryCSV"
}
