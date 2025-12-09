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
    "Path,PathLength,Warning,ErrorMessage,Timestamp,Size(Bytes),Owner" | Out-File $OutputCSV
    "Folder,InaccessibleCount,LongPathCount" | Out-File $SummaryCSV

    $items = Get-ChildItem -Path $NetworkShare -Recurse -ErrorAction SilentlyContinue
    $total = $items.Count
    $count = 0

    if ($PSVersionTable.PSVersion.Major -ge 7) {
        # Use dynamic script block for PowerShell 7 parallel logic
        $parallelScript = {
            param($items,$OutputCSV,$SummaryCSV,$ThrottleLimit,$total)

            $folderSummary = [System.Collections.Concurrent.ConcurrentDictionary[string,object]]::new()

            $items | ForEach-Object -Parallel {
                param($OutputCSV,$folderSummary,$total)

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
                    $pathLength = $_.FullName.Length
                    $warning = if ($pathLength -gt 260) { "Path exceeds 260 characters" } else { "" }

                    if ($pathLength -gt 260) {
                        Write-Host "WARNING: Long path detected ($pathLength chars): $($_.FullName)" -ForegroundColor Yellow
                    }

                    "$($_.FullName),$pathLength,$warning,$errorMsg,$timestamp,$size,$owner" | Out-File -Append -FilePath $OutputCSV

                    $folder = Split-Path $_.FullName -Parent
                    $folderSummary.AddOrUpdate($folder,
                        @{Inaccessible=1;LongPaths=(if ($pathLength -gt 260){1}else{0})},
                        { param($key,$old) @{Inaccessible=$old.Inaccessible+1;LongPaths=$old.LongPaths+(if ($pathLength -gt 260){1}else{0})} })
                }

                [System.Threading.Interlocked]::Increment([ref]$using:count) | Out-Null
                $percent = [math]::Round(($using:count / $total) * 100, 2)
                Write-Progress -Activity "Scanning Network Share" -Status "$percent% Complete" -PercentComplete $percent

            } -ArgumentList $OutputCSV,$folderSummary,$total -ThrottleLimit $ThrottleLimit

            $folderSummary.GetEnumerator() | ForEach-Object {
                "$($_.Key),$($_.Value.Inaccessible),$($_.Value.LongPaths)" | Out-File -Append -FilePath $SummaryCSV
            }
        }

        & $parallelScript $items $OutputCSV $SummaryCSV $ThrottleLimit $total
    }
    else {
        # Sequential logic for PowerShell 5.1
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
                $pathLength = $item.FullName.Length
                $warning = if ($pathLength -gt 260) { "Path exceeds 260 characters" } else { "" }

                if ($pathLength -gt 260) {
                    Write-Host "WARNING: Long path detected ($pathLength chars): $($item.FullName)" -ForegroundColor Yellow
                }

                "$($item.FullName),$pathLength,$warning,$errorMsg,$timestamp,$size,$owner" | Out-File -Append -FilePath $OutputCSV

                $folder = Split-Path $item.FullName -Parent
                if ($folderSummary.ContainsKey($folder)) {
                    $folderSummary[$folder].Inaccessible++
                    if ($pathLength -gt 260) { $folderSummary[$folder].LongPaths++ }
                } else {
                    $folderSummary[$folder] = [PSCustomObject]@{ Inaccessible = 1; LongPaths = (if ($pathLength -gt 260) {1} else {0}) }
                }
            }

            $count++
            $percent = [math]::Round(($count / $total) * 100, 2)
            Write-Progress -Activity "Scanning Network Share" -Status "$percent% Complete" -PercentComplete $percent
        }

        foreach ($folder in $folderSummary.Keys) {
            "$folder,$($folderSummary[$folder].Inaccessible),$($folderSummary[$folder].LongPaths)" | Out-File -Append -FilePath $SummaryCSV
        }
    }

    Write-Host "Scan complete. Detailed results saved to $OutputCSV and folder summary to $SummaryCSV"
}
