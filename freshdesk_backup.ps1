# This easy PowerShell script will perform a Backup from you specified start date of the Following Data:
# Tickets, Contacts, Companies, Groups, Forums

## Config ##
$path = ".\" #end it with a \
$dataRetention = 14 # keep files for 14 days

# API URL
$url = "https://infosys-kommunal.freshdesk.com/api/v2/account/export"

# User authentication Freshdesk API
$username = "Your API Key"
$password = "X" # X is the Right password for Freshdesk
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username,$password)))

# Path to requestData.json. Edit the json Value "start_date" to specify from which date you wanna start backups. 
# By default it ist set to 2022.
$jsonFilePath = ".\RequestData.json"

## Programm ##

# Read requestdata.json and replace Date Time with offset -2 hours. 
$date = Get-Date -Format "yyyy-MM-dd"
$time = (Get-Date).AddHours(-2).ToString("HH:mm:ss")
Start-Sleep -Seconds 5
$data = Get-Content -Path $jsonFilePath -Raw
$data = $data -replace "{Date}", $Date -replace "{Time}", $Time

# Send POST-Request
$response = Invoke-RestMethod -Uri $url -Method Post -Body $data -ContentType "application/json" -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)}
Write-Host "Export initialized"

# Waiting for download link to appear
$url = $response.job.link.href
$response = Invoke-RestMethod -Uri $url -Method Get -Body $data -ContentType "application/json" -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)}
Write-Host "Waiting for finish export..."

while($response.progress -ne 100)
{
Start-Sleep -Seconds 30
$response = Invoke-RestMethod -Uri $url -Method Get -Body $data -ContentType "application/json" -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)}
}

# If download link appear, start download
$finalPath = $path + "Freshdesk_$date.zip"
$downloadUrl = $response.data.download_attachment.url -replace "_", "v2"
Write-Host "Download started"
$response = Invoke-WebRequest -Uri $downloadUrl -ContentType "application/json" -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} -OutFile $finalPath
Write-Host "Download finished"

# Delete backups older then specified days.
$oldBackups = Get-ChildItem -Path $path | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$dataRetention) }
Write-Host "Delete files older then $dataRetention in $path"

# Dateien löschen
$oldBackups | ForEach-Object {
    $_ | Remove-Item -Force
    Write-Host "$($_.FullName) succesfull deleted" 
}

Write-Host "Skript finished. Bye"