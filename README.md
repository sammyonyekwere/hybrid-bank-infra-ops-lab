# hybrid-bank-infra-ops-lab
Hybrid Banking Infrastructure Operations Lab simulating Azure, Windows Server, networking, database operations, monitoring, incident response, and disaster recovery in a hybrid cloud environment.

## Current Progress

The Windows Server health-check runbook and PowerShell script are currently in progress. The script now reports:

- Server name, operating-system information, and last boot time
- Automatically configured services that are not running
- Top processes by CPU usage and sampled total CPU usage
- Available and total memory
- Disk size and remaining space for mounted volumes
- System error events from the previous 24 hours
- Five most recently installed hotfixes

Each check has a labelled heading in the console output, including:

```text
== Server ==
== Services ==
== CPU ==
== Memory ==
== Disk ==
== Event Logs ==
== Patch Level ==
```

## Running the Health Check

Run the script from PowerShell on the Windows Server:

```powershell
.\scripts\Get-ServerHealth.ps1
```

The script starts a transcript and saves the output as a timestamped file in the current working directory:

```text
health-yyyyMMdd-HHmm.txt
```

The script uses Windows administrative and diagnostic commands such as `Get-Service`, `Get-Counter`, `Get-Volume`, `Get-WinEvent`, and `Get-HotFix`. Run it with an account that has permission to read the required system and event-log information.

## Project Structure

```text
scripts/
  Get-ServerHealth.ps1       Windows Server health-check script
docs/
  runbooks/
    server-health.md         Health-check notes and runbook documentation
```
