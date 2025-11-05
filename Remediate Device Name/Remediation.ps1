<#
.SYNOPSIS
Post-enrolment device rename script for Windows Autopilot devices.

.DESCRIPTION
This script ensures Windows 11 Autopilot devices are renamed according to your desired naming convention,
using the BIOS serial number. It corrects the known issue where %SERIAL% fails during Autopilot deployment
due to invalid characters or inconsistent SMBIOS serial formatting (common with some Dell models).

If the device name does not already match the intended pattern, it:
- Retrieves and sanitises the BIOS serial number
- Constructs a new name using the defined template (e.g. PrefixEx-<Serial>)
- Validates name length and characters
- Renames the device if required
- Logs all actions to the Intune Management Extension logs folder

.NOTES
Author: Damien.Cresswell - Sistena Ltd.
Last edit: 05/11/2025
#>

#================= CONFIGURATION =================
$Prefix = "PrefixEx-"                          # Desired prefix for all devices
$LogPath = "$env:ProgramData\IntuneRenamer\RenameLog.txt"
$MaxNameLength = 15                       # Windows hostname length limit
# Only run on Autopilot-enrolled devices (checked via registry); set to $false to run everywhere
$OnlyOnAutopilot = $true
#=================================================

# Ensure log directory exists
$logDir = Split-Path $LogPath
if (!(Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $LogPath -Value "$timestamp : $Message"
}

function Test-IsAutopilotDevice {
    # Checks common registry locations that exist on Autopilot devices
    $paths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\Autopilot',
        'HKLM:\SOFTWARE\Microsoft\Provisioning\Diagnostics\AutoPilot'
    )
    foreach ($p in $paths) {
        if (Test-Path -Path $p) { return $true }
    }
    return $false
}

function Test-IsVirtualMachine {
    # Detects common VM platforms using manufacturer/model heuristics
    try {
        $cs = Get-CimInstance -ClassName Win32_ComputerSystem
        $manufacturer = ($cs.Manufacturer | Out-String).Trim()
        $model = ($cs.Model | Out-String).Trim()

        $patterns = @(
            'Microsoft Corporation.*Virtual',   # Hyper-V / Azure
            '^VMware',                          # VMware
            'VirtualBox',                       # Oracle VirtualBox
            'KVM',                              # KVM/QEMU
            'QEMU',                             # QEMU
            'Xen',                              # Xen / AWS older
            'HVM domU',                         # Xen HVM
            'Parallels',                        # Parallels
            'BHYVE',                            # bhyve
            'OpenStack',                        # OpenStack
            'Bochs'                             # Bochs
        )

        foreach ($p in $patterns) {
            if ($manufacturer -match $p -or $model -match $p) { return $true }
        }

        return $false
    } catch {
        return $false
    }
}

try {
    Write-Log "=== Starting Autopilot Rename Script ==="

    if ($OnlyOnAutopilot -and -not (Test-IsAutopilotDevice)) {
        Write-Log "Device does not appear to be Autopilot-enrolled. Skipping rename."
        Write-Log "=== Completed successfully (no-op on non-Autopilot) ==="
        exit 0
    }

    if (Test-IsVirtualMachine) {
        Write-Log "Virtual machine detected (manufacturer/model heuristic). Skipping rename."
        Write-Log "=== Completed successfully (no-op on VM) ==="
        exit 0
    }

    $currentName = $env:COMPUTERNAME
    Write-Log "Current hostname: $currentName"

    # Get and clean the serial number
    $rawSerial = (Get-CimInstance Win32_BIOS).SerialNumber.Trim()
    $cleanSerial = $rawSerial -replace '[^A-Za-z0-9-]', ''

    if (-not $cleanSerial) {
        Write-Log "ERROR: Serial number could not be retrieved or cleaned."
        exit 1
    }

    Write-Log "Raw serial: $rawSerial | Cleaned serial: $cleanSerial"

    # Construct new name and trim if too long
    $newName = "$Prefix$cleanSerial"
    if ($newName.Length -gt $MaxNameLength) {
        $newName = $newName.Substring(0, $MaxNameLength)
        Write-Log "Truncated new name to $newName due to length limit."
    }

    # Only rename if different
    if ($newName -ne $currentName) {
        Write-Log "Renaming device to: $newName"
        try {
            Rename-Computer -NewName $newName -Force -ErrorAction Stop
            Write-Log "Rename succeeded. Restart required."
        } catch {
            Write-Log "Rename failed: $($_.Exception.Message)"
            exit 1
        }
    } else {
        Write-Log "Device name already matches desired format ($newName). No action taken."
    }

    Write-Log "=== Completed successfully ==="
    exit 0

} catch {
    Write-Log "Fatal error: $($_.Exception.Message)"
    exit 1
}

