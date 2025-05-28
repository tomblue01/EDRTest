# This PowerShell script will execute a series of other scripts (.bat and .ps1 files)
# with a 35-minute pause between each execution.
#
# IMPORTANT:
# 1. Ensure all the specified scripts (ChangePerms.bat, Hollowing.ps1, etc.) are
#    located in the same directory as this PowerShell script, or provide their
#    full paths.
# 2. Running these scripts, especially those related to "MemoryDump", "ProcessInjection",
#    "ReverseShell", or "WMIPersistence", can have significant security implications
#    and may trigger security software (EDR, antivirus).
#    ONLY run this script in a controlled, isolated testing environment (e.g., a lab VM)
#    and with proper authorization.
# 3. Some scripts might require elevated privileges (Run as Administrator).
#    If a script fails, try running this entire PowerShell script as Administrator.

# Define the list of scripts to execute
$scriptsToRun = @(
    "Hollowing.ps1",
    "MemoryDump.ps1"
)

# Define the pause duration in minutes
$pauseMinutes = 2100

<# Write-Host "--------------------------------------------------" -ForegroundColor Yellow
Write-Host "                       ATTENTION!                     " -ForegroundColor Yellow
Write-Host "--------------------------------------------------" -ForegroundColor Yellow
Write-Host "Before running these tests, ensure the following:" -ForegroundColor Yellow
Write-Host "1. You have Apache running on your Kali Box." -ForegroundColor Yellow
Write-Host "2. 'popup.ps1' is located in your Apache web root (e.g., /var/www/html/)." -ForegroundColor Yellow
Write-Host "3. The Netcat listener command 'nc -lvp 4444' was run and is active on your Kali Box." -ForegroundColor Yellow
Write-Host "--------------------------------------------------" -ForegroundColor Yellow
Write-Host ""

# Require user to hit Enter to proceed
Read-Host "Press Enter to proceed with the script execution..."

Write-Host "Starting script execution sequence..." -ForegroundColor Green
Write-Host "Each script will be followed by a $pauseMinutes minute pause." -ForegroundColor Green
Write-Host "" #>

# Loop through each script in the list
foreach ($scriptName in $scriptsToRun) {
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath $scriptName

    Write-Host "--------------------------------------------------" -ForegroundColor Cyan
    Write-Host "Attempting to execute: '$scriptName'" -ForegroundColor Yellow
    Write-Host "Full path: '$scriptPath'" -ForegroundColor DarkYellow
    Write-Host "--------------------------------------------------" -ForegroundColor Cyan

    # Check if the script file exists
    if (Test-Path $scriptPath) {
        try {
            # Determine how to execute based on file extension
            if ($scriptName.EndsWith(".bat", [System.StringComparison]::OrdinalIgnoreCase)) {
                # For .bat files, use Start-Process to run them in a new command prompt
                Write-Host "Executing .bat file using Start-Process..." -ForegroundColor White
                Start-Process -FilePath $scriptPath -Wait -NoNewWindow # -NoNewWindow keeps it from popping up a cmd window
                Write-Host "'$scriptName' execution completed." -ForegroundColor Green
            } elseif ($scriptName.EndsWith(".ps1", [System.StringComparison]::OrdinalIgnoreCase)) {
                # For .ps1 files, use the call operator (&) to execute them
                Write-Host "Executing .ps1 file using the call operator..." -ForegroundColor White
                & $scriptPath # The call operator runs the script in the current scope or a child scope
                Write-Host "'$scriptName' execution completed." -ForegroundColor Green
            } else {
                Write-Host "Skipping '$scriptName': Unsupported file type." -ForegroundColor Red
            }
        } catch {
            Write-Host "An error occurred during '$scriptName' execution:" -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red
            Write-Host "Continuing to next script..." -ForegroundColor Red
        }
    } else {
        Write-Host "Error: Script file not found at '$scriptPath'. Skipping." -ForegroundColor Red
    }

    # Pause only if it's not the last script
    if ($scriptName -ne $scriptsToRun[-1]) {
        Write-Host ""
        Write-Host "Pausing for $pauseMinutes minutes before the next script..." -ForegroundColor Blue
        Start-Sleep -Seconds $pauseMinutes
        Write-Host "Pause ended. Resuming execution." -ForegroundColor Blue
        Write-Host ""
    }
}

Write-Host "--------------------------------------------------" -ForegroundColor Green
Write-Host "All scripts have been executed or skipped." -ForegroundColor Green
Write-Host "--------------------------------------------------" -ForegroundColor Green