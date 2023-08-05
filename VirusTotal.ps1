#VirusTotal Tool
#Uses VT API3 and PS7
#Current functions:
#- Upload a file to VT
#- Get meta info about file
#- Get file virus scan results
#- Get file link to VTsite with GUI results
#- Scan URL from VT
#- Get URL virus scan results
#- Get URL link to VTsite with GUI results

#User variables
$APIKey = 'ABC123'
$File   = 'C:\test.pdf'
$URL    = 'https://example.com'

#Premade variables
$FileLargeURL = 'https://www.virustotal.com/api/v3/files/upload_url'
$FileGUIURL   = 'https://www.virustotal.com/gui/file'
$URLGUIURL    = 'https://www.virustotal.com/gui/url'
$ScanuRL      = 'https://www.virustotal.com/api/v3/urls'

Clear-Host

# Get Large File URL
function GetLargeFileURL {
    $FileLargeURLGet = Invoke-WebRequest -Uri $FileLargeURL -Method GET -Headers @{
        'x-apikey' = $APIKey
    } -UseBasicParsing
    $FileLargeURLGet = ($FileLargeURLGet | ConvertFrom-Json).Data
    $FileLargeURLGet
}

# Upload file
function FileUpload {
    $FileUpload = Invoke-WebRequest -Uri $FileLargeURLGet -Method POST -Headers @{
        'accept' = 'application/json'
        'x-apikey' = $APIKey
    } -UseBasicParsing -Form @{
        'file' = Get-Item -Path $File
    } -ContentType 'multipart/form-data'
    $FileUploadURL = ($Fileupload | ConvertFrom-Json).data.links.self
    $FileUploadURL
}

#Wait for file scan
function CheckFileStatus {
    $i = 1
    do {
        #Check file status
        $FileReport = Invoke-WebRequest -Uri $FileUploadURL -Method GET -Headers @{
            'x-apikey' = $APIKey 
        }
        $FileReportStatus = ($FileReport | ConvertFrom-Json).Data.Attributes.Status
        if ($FileReportStatus -eq 'completed') {
            $FileReport = $FileReport.Content | ConvertFrom-Json
        } elseif ($FileReportStatus -eq 'queued') {
            Write-Host ''
            Write-Host (('Attempt #') + $i + (': Job still running. Waiting 10 seconds before checking again...'))
            #$FileReportStatus
            Start-Sleep -Seconds 10
            $i++
        } else {
            Write-Host "idk"
        }
    } until (($FileReportStatus -eq 'completed') -or $i -eq 30)
    if ($i -ge 30) {
        Write-Host "Fail"
        $FileReport = "Fail"
    }
    $FileReport
}

#Get file hash
function GetFileHash {
    $FileHash = $FileReport.meta.file_info.sha256
    $FileHash
}

#Get file size
function FileSize {
    $FileSize = ($FileReport.meta.file_info.size).ToString("N0")
    if (($FileSize/1024/1024 -lt 1) -and ($FileSize/1024 -lt 1)) {
        $FileSize = "$FileSize Bytes"
    } elseif (($FileSize/1024/1024 -lt 1) -and ($FileSize/1024 -gt 1)) {
        $FileSize = ($FileSize/1024).ToString("N0")
        $FileSize = "$FileSize KiloBytes"
    } elseif ($FileSize/1024 -ge 1) {
        $FileSize = ($FileSize/1024/1024).ToString("N0")
        $FileSize = "$FileSize MegaBytes"
    }
    $FileSize
}

#Link to VT site to see GUI results
function FileGUILink {
    $FileGUILink = $FileGUIURL + '/' + $FileHash
    $FileGUILink
}

#File's individual reports from each AV
function FileVirusReports {
    $AVResults = $FileReport.data.attributes.results
    $AVEngines = ($AVResults | Get-Member | Where-Object -Property MemberType -eq 'NoteProperty').Name
    $AVTable = @()
    foreach ($AV in $AVEngines){
        $AVScan = $AVResults.$AV
        $AVTable += $AVScan
    }
    $AVTable
}

#Link to download file - Won't work without "special privilege"
#function DownloadLink {
#    $DownloadURL  = 'https://www.virustotal.com/api/v3/files/' + $FileHash + '/download_url'
#    $DownloadLink = Invoke-WebRequest -Uri $DownloadURL -Headers @{
#        'x-apikey' = $APIKey 
#    } -UseBasicParsing -ContentType 'application/json'
#}

#Scan a site
function ScanSite {
    $ScanSite = Invoke-RestMethod -Uri $ScanuRL -Method Post -ContentType 'application/x-www-form-urlencoded' -Headers @{
        'accept'   = 'application/json'
        'x-apikey' = $APIKey
    } -Body @{
        'url' = $URL
    }
    $ScanSite
}

#Get report of scanned site
function SiteReport {
    $SiteID    = ($ScanSite.data.id -split '-')[1]
    $URLLink   = $ScanURL + '/' + $SiteID
    $URLReport = Invoke-RestMethod -Method GET -Uri $URLLink -Headers @{
        'accept'   = 'application/json'
        'x-apikey' = $APIKey
    }
    $URLReport
}

function URLGUILink {
    $SiteID     = ($ScanSite.data.id -split '-')[1]
    $URLGUILink = $URLGUIURL + '/' + $SiteID
    $URLGUILink
}

#Site's individual reports from each AV
function SiteVirusReports {
    $AVResults = $SiteReport.data.attributes.last_analysis_results
    $AVEngines = ($AVResults | Get-Member | Where-Object -Property MemberType -eq 'NoteProperty').Name
    $AVTable = @()
    foreach ($AV in $AVEngines){
        $AVScan = $AVResults.$AV
        $AVTable += $AVScan
    }
    $AVTable
}

#Run

##Select Operation
function OperationSelect {
    Write-Host 'Select Operation:

1. Scan File
2. Scan URL
'
    do {
        $OperationSelect = Read-Host -Prompt "Select operation by number"
        if ($OperationSelect -notin 1..2){
            Write-Warning "Select a valid operation by number"
            Write-Host ""
        }
    } until ($OperationSelect -in 1..2)
    $OperationSelect
}

$OperationSelect = OperationSelect

switch ($OperationSelect) {
    1 {
        $FileLargeURLGet = GetLargeFileURL
        $FileUploadURL = FileUpload
        $FileReport = CheckFileStatus
        $FileHash = GetFileHash
        $FileSize = FileSize
        $FileGUILink = FileGUILink
        $FileVirusReports = FileVirusReports# | Sort-Object -Property Category | Format-Table -Property engine_name,category,result,method,engine_version,engine_update
        #$DownloadLink = DownloadLink
    }
    2 {
        $ScanSite = ScanSite
        $SiteReport = SiteReport
        $URLGUILink = URLGUILink
        $SiteVirusReports = SiteVirusReports# | Sort-Object -Property Category | Format-Table -Property engine_name,category,result,method
    }
}

#Report

Write-Host $FileReport
Write-Host $FileVirusReports
Write-Host $SiteReport
Write-Host $SiteVirusReports
