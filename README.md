# NetworkShareTools

## Overview
**NetworkShareTools** is a PowerShell module designed to scan network shares for inaccessible files and folders. It provides:
- Detailed CSV reports of inaccessible items (including path, error message, timestamp, size, and owner).
- Folder-level summary of inaccessible counts.
- Multi-threaded scanning for speed.
- Progress indication during execution.

---

## Features
✅ Multi-threaded scanning using `ForEach-Object -Parallel`  
✅ Detailed error logging to CSV  
✅ Folder-level summary report  
✅ Includes file size and owner information  
✅ Fully parameterized for flexibility  

---

## Installation
1. Clone or download this repository.
2. Run the following powershell.
   ````powershell
.\Install-NetworkShareTools.ps1
4. ```powershell
   Import-Module NetworkShareTools

## Usage

Get-NetworkShareAccessReport `
    -NetworkShare "\\Server\Share" `
    -OutputCSV "C:\AccessErrors.csv" `
    -SummaryCSV "C:\FolderSummary.csv" `
    -ThrottleLimit 15

<img width="446" height="101" alt="image" src="https://github.com/user-attachments/assets/5c91a786-4839-4e96-89d9-a6f699b243ef" />


---

## Output

Detailed Report (CSV):

Columns: Path, ErrorMessage, Timestamp, Size(Bytes), Owner


Folder Summary (CSV):

Columns: Folder, InaccessibleCount



---


## Requirements

PowerShell 7.0 or later

Permissions to access the network share


---

## Roadmap

 Add email notifications on completion
 
 Add parameter validation
 
 Add logging to Event Viewer
 
 Add option to include successful access logs


---

License
This project is licensed under the MIT License.

Contributing
Pull requests are welcome! For major changes, please open an issue first to discuss what you would like to change.

Author
Cody Frazier

github.com/dorkfish87
