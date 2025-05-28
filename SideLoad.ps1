# Create test directory
$testDir = "C:\Temp\SideloadTest"
New-Item -ItemType Directory -Path $testDir -Force | Out-Null

# Copy a legitimate executable
$wmplayerPath = "C:\Program Files\Windows Media Player\wmplayer.exe"
Copy-Item -Path $wmplayerPath -Destination "$testDir\wmplayer.exe" -Force

# Create a file simulating a malicious DLL with the same name as a legitimate DLL
$dllContent = "This is a simulated malicious DLL for testing EDR detection"
[System.IO.File]::WriteAllText("$testDir\wmp.dll", $dllContent) # Changed to wmp.dll

# Run the executable from the non-standard location
Write-Host "Launching wmplayer.exe from test directory..."
Start-Process -FilePath "$testDir\wmplayer.exe"

# Wait a moment for detection
Start-Sleep -Seconds 5

# Cleanup
Get-Process wmplayer* | Stop-Process -Force -ErrorAction SilentlyContinue
Remove-Item -Path $testDir -Recurse -Force