Windows Autopilot Device Rename Script
📝 Overview

This PowerShell script automatically renames Windows 11 Autopilot-enrolled devices after deployment to align with your organisation’s standard naming convention.
It addresses a known issue where the %SERIAL% variable fails or produces invalid names during Autopilot provisioning — particularly on Dell hardware where SMBIOS serials may include invalid or unexpected characters.

The script ensures device names remain consistent, compliant, and traceable — all while safely logging each action to assist with audit or troubleshooting.

⚙️ Features

✅ Automatically retrieves and sanitises the BIOS serial number

✅ Builds a new device name using a configurable prefix (e.g. PrefixEx-<Serial>)

✅ Validates hostname length (≤ 15 characters) and allowed characters

✅ Detects and skips virtual machines (Azure, VMware, etc.)

✅ Optionally restricts renaming to Autopilot-enrolled devices

✅ Logs all activity to the Intune Management Extension logs folder

✅ Fully compatible with Windows 11 Autopilot deployments

📦 Example Configuration

In the configuration block near the top of the script:

#================= CONFIGURATION =================
$Prefix = "PrefixEx-"                          # Desired prefix for all devices
$LogPath = "$env:ProgramData\IntuneRenamer\RenameLog.txt"
$MaxNameLength = 15                       # Windows hostname length limit
$OnlyOnAutopilot = $true                  # Restrict to Autopilot devices only
#=================================================


You can adjust:

Prefix → your organisation’s prefix (e.g. PrefixEx-, CORP-, etc.)

MaxNameLength → typically left at 15 (Windows limit)

OnlyOnAutopilot → set to $false if you wish to run on all systems

🖥️ How It Works

The script checks whether the device is Autopilot-enrolled using registry keys.

It verifies the machine is not virtualised (to prevent renaming VMs).

Retrieves the BIOS serial number via WMI (Win32_BIOS).

Sanitises the serial to remove non-alphanumeric or invalid characters.

Combines the prefix and cleaned serial to form a valid hostname.

Renames the device if the name doesn’t already match the expected format.

Logs all steps to C:\ProgramData\IntuneRenamer\RenameLog.txt.

📄 Example Log Output
2025-11-05 10:12:01 : === Starting Autopilot Rename Script ===
2025-11-05 10:12:01 : Current hostname: DESKTOP-ABC123
2025-11-05 10:12:02 : Raw serial: /EXAMPLESERIAL/CNWSC0055A12GM/
2025-11-05 10:12:02 : Cleaned serial: EXAMPLESERIALCNWSC0055A12GM
2025-11-05 10:12:02 : Renaming device to: ExPrefix-EXAMPLESERIAL
2025-11-05 10:12:04 : Rename succeeded. Restart required.
2025-11-05 10:12:04 : === Completed successfully ===

🚀 Deployment Options

You can deploy this script using:

Intune Device Configuration > PowerShell scripts

Intune Remediation scripts (recommended for periodic recheck)

Task Scheduler / Startup Script (for local or lab testing)

When deploying through Intune, ensure:

Execution policy is unrestricted (Bypass)

Script runs in system context

Device restarts automatically after rename

🔐 Requirements

Windows 10/11 (Autopilot-capable build)

PowerShell 5.1 or newer (PowerShell 7 recommended)

Administrative permissions (required for renaming)

🧰 Logging Location
Type	Path
Log File	C:\ProgramData\IntuneRenamer\RenameLog.txt
Directory	Automatically created if missing
📋 Notes

The script does not use deprecated modules such as MSOnline.

If the rename fails, the failure reason will be logged.

No permanent registry or system configuration changes are made beyond the rename itself.

🧑‍💻 Author

Damien Cresswell – Sistena Ltd
Last edited: 05 November 2025

📜 Licence

This script is provided as-is without warranty.
You may freely modify or redistribute it for internal or educational use, provided credit remains intact.
