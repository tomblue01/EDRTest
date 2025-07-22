# Create test directory
$testDir = "C:\Temp\SideloadTest"
New-Item -ItemType Directory -Path $testDir -Force | Out-Null

# Copy a legitimate executable
$wmplayerPath = "C:\Program Files\Windows Media Player\wmplayer.exe"
if (Test-Path $wmplayerPath) {
    Copy-Item -Path $wmplayerPath -Destination "$testDir\wmplayer.exe" -Force
} else {
    Write-Error "Source wmplayer.exe not found at '$wmplayerPath'. Aborting."
    return
}

# Create a file simulating a malicious DLL with the same name as a legitimate DLL
$dllContent = "This is a simulated malicious DLL for testing EDR detection"
[System.IO.File]::WriteAllText("$testDir\wmp.dll", $dllContent)

# Run the executable from the non-standard location
Write-Host "Launching wmplayer.exe from test directory..." -ForegroundColor Yellow
$startInfo = New-Object System.Diagnostics.ProcessStartInfo
$startInfo.FileName = "$testDir\wmplayer.exe"
$startInfo.WorkingDirectory = $testDir
$startInfo.UseShellExecute = $false  # Non-interactive execution
$startInfo.RedirectStandardError = $true  # Capture error stream
$startInfo.RedirectStandardOutput = $true  # Capture output stream
$proc = New-Object System.Diagnostics.Process
$proc.StartInfo = $startInfo

try {
    $started = $proc.Start()
    if ($started) {
        Write-Host "Successfully launched wmplayer.exe (PID: $($proc.Id))" -ForegroundColor Green
        # Wait a moment for detection
        Start-Sleep -Seconds 5
        # Check if the process is still running
        if (-not $proc.HasExited) {
            Write-Host "Terminating wmplayer.exe (PID: $($proc.Id))..." -ForegroundColor Yellow
            $proc.Kill()
            Write-Host "wmplayer.exe terminated successfully." -ForegroundColor Green
        } else {
            Write-Warning "wmplayer.exe exited prematurely. Exit Code: $($proc.ExitCode)"
            $standardOutput = $proc.StandardOutput.ReadToEnd()
            $errorMessage = $proc.StandardError.ReadToEnd()
            if ($standardOutput) { Write-Host "Standard Output: $standardOutput" -ForegroundColor Gray }
            if ($errorMessage) { Write-Error "Error Output: $errorMessage" }
        }
    } else {
        Write-Error "Failed to launch wmplayer.exe."
    }
} catch {
    Write-Error "An error occurred while launching wmplayer.exe: $($_.Exception.Message)"
    $standardOutput = $proc.StandardOutput.ReadToEnd()
    $errorMessage = $proc.StandardError.ReadToEnd()
    if ($standardOutput) { Write-Host "Standard Output: $standardOutput" -ForegroundColor Gray }
    if ($errorMessage) { Write-Error "Error Output: $errorMessage" }
} finally {
    $proc.Dispose()
}

# Cleanup
Write-Host "Cleaning up test directory..." -ForegroundColor Yellow
Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "Script execution completed." -ForegroundColor Green