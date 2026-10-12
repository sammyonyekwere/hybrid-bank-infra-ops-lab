# Windows Server Health Runbook

## Purpose

This runbook documents the first Windows Server health checks for the hybrid banking infrastructure lab. The goal is to collect a repeatable baseline for availability, performance, storage, operating-system errors, and patching.

The checks are read-only. They do not restart services, change configuration, or install updates.

## Running the Check

From the repository root, run:

```powershell
.\scripts\Get-ServerHealth.ps1
```

The script uses `Start-Transcript` to capture the console output in a timestamped file:

```text
health-yyyyMMdd-HHmm.txt
```

Keep the transcript with the date and server name when using it as an operational record. Review the output from top to bottom and investigate unexpected values rather than treating every result as an automatic failure.

## Checks and Explanations

### 1. Server identity and uptime

```powershell
hostname
Get-CimInstance Win32_OperatingSystem |
  Select-Object CSName, Caption, LastBootUpTime
```

This confirms which server is being inspected, identifies the operating system, and shows when it last started. Uptime helps explain recent service interruptions and can indicate whether a server was restarted during an incident or maintenance window.

### 2. Automatically configured services

```powershell
Get-Service |
  Where-Object { $_.StartType -eq 'Automatic' -and $_.Status -ne 'Running' }
```

This lists services configured to start automatically but not currently running. These services may affect applications, authentication, printing, monitoring, or other dependencies. Each result should be checked against the server's intended role because some services can be intentionally stopped.

#### Services observed during the initial review

The initial review recorded the following observations:

- **Print Spooler** — configured as Automatic and currently running. It depends on HTTP and Remote Procedure Call (RPC) services.
- **Windows Time** — configured as Automatic (Delayed Start) and currently running. No dependencies were recorded in the initial notes.

These observations provide context for interpreting the service check. A service that is expected to run but appears in the output requires investigation of its dependencies, recent events, and service-specific logs.

### 3. CPU usage

```powershell
Get-Process |
  Sort-Object CPU -Descending |
  Select-Object -First 10 Name, Id, CPU, WS
Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 2 -MaxSamples 3
```

The first command identifies processes with the highest accumulated CPU time and includes working-set memory (`WS`) for context. The performance counter samples total processor utilization three times, two seconds apart, to show current CPU pressure.

A high-CPU process is a lead for investigation, not proof of a fault. Compare the samples with application activity, scheduled jobs, and the time of any reported incident.

### 4. Memory

```powershell
Get-CimInstance Win32_OperatingSystem | Select-Object `
  @{n='FreeGB'; e={[math]::Round($_.FreePhysicalMemory/1MB,1)}},
  @{n='TotalGB'; e={[math]::Round($_.TotalVisibleMemorySize/1MB,1)}}
```

This reports free and total physical memory in gigabytes. Low free memory can cause paging, slower applications, and increased response times. Use the result as a baseline and investigate it alongside process working-set values and application performance.

The conversion divides the Windows CIM memory values, which are reported in kilobytes, by `1MB` and rounds the result to one decimal place.

### 5. Disk capacity

```powershell
Get-Volume |
  Where-Object DriveLetter |
  Select-Object DriveLetter,
    @{n='SizeGB'; e={[math]::Round($_.Size/1GB,1)}},
    @{n='FreeGB'; e={[math]::Round($_.SizeRemaining/1GB,1)}}
```

This reports the total and remaining capacity for volumes with drive letters. Low free space can prevent applications from writing data, interfere with Windows updates, and cause logs or databases to fail. Review each drive according to its role, especially drives used for databases, transaction logs, or event logs.

Volumes without drive letters are excluded from this first operational check.

### 6. System error events

```powershell
Get-WinEvent -FilterHashtable @{
  LogName='System'
  Level=2
  StartTime=(Get-Date).AddHours(-24)
} -MaxEvents 20 |
  Select-Object TimeCreated, Id, ProviderName, Message
```

This retrieves up to 20 error-level events from the Windows System log during the previous 24 hours. Event logs act as a black-box recorder for issues such as service failures, driver problems, storage errors, and unexpected shutdowns.

Events should be correlated with the server's uptime, service status, and the reported incident time. The command limits the output to recent errors so the transcript remains useful during an initial triage.

### 7. Patch level

```powershell
Get-HotFix |
  Sort-Object InstalledOn -Descending |
  Select-Object -First 5
```

This displays the five most recently installed Windows hotfixes. The information helps establish whether the server has received recent maintenance and provides useful context when investigating a change that followed patching.

The output is not a complete compliance report. Use the organization's patch-management system to confirm the required update baseline.

## Interpreting the Results

During review:

1. Confirm the transcript belongs to the intended server.
2. Record any automatically configured services that are stopped.
3. Compare CPU, memory, and disk values with normal baseline values.
4. Correlate System log errors with uptime and service findings.
5. Note the latest hotfix date and compare it with the maintenance schedule.
6. Escalate findings that affect availability, data integrity, authentication, or capacity.

## Scope and Next Steps

The current script establishes a foundational health check. Future runbook improvements may include:

- Disk free-space thresholds and explicit warnings
- Service-specific dependency and failure-action checks
- Network connectivity and DNS checks
- Application and database health checks
- Structured output for monitoring or automated reporting
