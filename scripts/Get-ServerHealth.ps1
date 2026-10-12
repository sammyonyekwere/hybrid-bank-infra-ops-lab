Start-Transcript -Path ".\health-$(Get-Date -Format yyyyMMdd-HHmm).txt"

# Check 1 — Which server, how long up
Write-Host "== Server =="
hostname
Get-CimInstance Win32_OperatingSystem | Select-Object CSName, Caption, LastBootUpTime

# Check 2 — Services that should run but do not
Write-Host "== Services =="
Get-Service | Where-Object { $_.StartType -eq 'Automatic' -and $_.Status -ne 'Running' }

# Check 3 — CPU
Write-Host "== CPU =="
Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 Name, Id, CPU, WS
Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 2 -MaxSamples 3

# Check 4 — Memory
Write-Host "== Memory =="
Get-CimInstance Win32_OperatingSystem | Select-Object `
  @{n='FreeGB';  e={[math]::Round($_.FreePhysicalMemory/1MB,1)}},
  @{n='TotalGB'; e={[math]::Round($_.TotalVisibleMemorySize/1MB,1)}}

# Check 5 — Disk space
Write-Host "== Disk =="
Get-Volume | Where-Object DriveLetter | Select-Object DriveLetter,
  @{n='SizeGB'; e={[math]::Round($_.Size/1GB,1)}},
  @{n='FreeGB'; e={[math]::Round($_.SizeRemaining/1GB,1)}}

# Check 6 — Event logs (the black-box recorder)
Write-Host "== Event Logs =="
Get-WinEvent -FilterHashtable @{ LogName='System'; Level=2; StartTime=(Get-Date).AddHours(-24) } -MaxEvents 20 |
  Select-Object TimeCreated, Id, ProviderName, Message

# Check 7 — Patch level
Write-Host "== Patch Level =="
Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 5

Stop-Transcript