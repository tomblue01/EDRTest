# Create test directory
$testDir = "C:\Temp\SideloadTest"
New-Item -ItemType Directory -Path $testDir -Force | Out-Null

# Copy a legitimate executable (cmd.exe instead of notepad.exe)
$targetExePath = "C:\Windows\System32\cmd.exe"
Copy-Item -Path $targetExePath -Destination "$testDir\cmd.exe" -Force

# Create a file simulating a malicious DLL with the same name as a legitimate DLL
$dllContent = "This is a simulated malicious DLL for testing EDR detection"
[System.IO.File]::WriteAllText("$testDir\version.dll", $dllContent)

# --- Identify and Copy Required DLLs (CRITICAL) ---
#  Use Process Monitor to determine the *minimum* set of DLLs.
#  For cmd.exe, this is likely to be very minimal.
$requiredDlls = @(
    "version.dll"  # Include version.dll in this test
    "kernel32.dll"
    "ntdll.dll"
)

foreach ($dll in $requiredDlls) {
    $systemDllPath = Join-Path "C:\Windows\System32" $dll
    if (Test-Path $systemDllPath) {
        Copy-Item -Path $systemDllPath -Destination "$testDir\$dll" -Force
        Write-Host "Copied required DLL: $dll"
    }
    else {
        Write-Warning "Required DLL not found: $dll.  Cmd.exe may fail to start correctly."
    }
}
# --- End DLL Copying ---


Add-Type -TypeDefinition @"
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;

public class ProcessHollowing {
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr OpenProcess(int dwDesiredAccess, bool bInheritHandle, int dwProcessId);
    
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool WriteProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, byte[] lpBuffer, uint nSize, out IntPtr lpNumberOfBytesWritten);
    
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool ReadProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, byte[] lpBuffer, uint dwSize, out IntPtr lpNumberOfBytesRead);
    
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr VirtualAllocEx(IntPtr hProcess, IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);
    
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool VirtualProtectEx(IntPtr hProcess, IntPtr lpAddress, uint dwSize, uint flNewProtect, out uint lpflOldProtect);
    
    [DllImport("kernel32.dll")]
    public static extern bool CloseHandle(IntPtr hObject);
    
    public static void SimulateHollowing(int targetProcessId) {
        // int processId = targetProcessId;  // Take process ID as a parameter
        System.Console.WriteLine("Hollowing process with PID: " + targetProcessId);
        
        // Access rights
        const int PROCESS_ALL_ACCESS = 0x1F0FFF;
        const uint MEM_COMMIT = 0x1000;
        const uint MEM_RESERVE = 0x2000;
        const uint PAGE_READWRITE = 0x04;
        const uint PAGE_EXECUTE_READWRITE = 0x40;
        
        System.Console.WriteLine("Opening process handle...");
        IntPtr hProcess = OpenProcess(PROCESS_ALL_ACCESS, false, targetProcessId);
        
        if (hProcess != IntPtr.Zero) {
            try {
                System.Console.WriteLine("Process handle: " + hProcess);
                
                // Simulate memory operations for hollowing
                System.Console.WriteLine("Simulating memory read operations...");
                byte[] buffer = new byte[1024];
                IntPtr bytesRead;
                Process targetProcess = Process.GetProcessById(targetProcessId);
                IntPtr baseAddress = targetProcess.MainModule.BaseAddress;
                ReadProcessMemory(hProcess, baseAddress, buffer, 1024, out bytesRead);
                
                System.Console.WriteLine("Simulating memory allocation...");
                IntPtr allocatedMemory = VirtualAllocEx(hProcess, IntPtr.Zero, 4096, MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE);
                
                if (allocatedMemory != IntPtr.Zero) {
                    System.Console.WriteLine("Allocated memory at: " + allocatedMemory);
                    
                    System.Console.WriteLine("Simulating memory protection change...");
                    uint oldProtect;
                    VirtualProtectEx(hProcess, allocatedMemory, 4096, PAGE_EXECUTE_READWRITE, out oldProtect);
                    
                    System.Console.WriteLine("Simulating memory write operations...");
                    IntPtr bytesWritten;
                    byte[] testData = new byte[16];
                    WriteProcessMemory(hProcess, allocatedMemory, testData, (uint)testData.Length, out bytesWritten);
                }
            } finally {
                CloseHandle(hProcess);
            }
        } else {
             System.Console.WriteLine("OpenProcess failed.  Error code: " + Marshal.GetLastWin32Error());
        }
    }
}
"@

# Run the executable from the non-standard location
Write-Host "Launching cmd.exe from test directory..."
$startInfo = New-Object System.Diagnostics.ProcessStartInfo
$startInfo.FileName = "$testDir\cmd.exe"
$startInfo.WorkingDirectory = $testDir
$startInfo.UseShellExecute = $false  # Important for capturing errors
$startInfo.RedirectStandardError = $true # Capture error stream
$startInfo.RedirectStandardOutput = $true
$proc = New-Object System.Diagnostics.Process
$proc.StartInfo = $startInfo

try {
    $proc.Start() | Out-Null # Suppress success output
    $proc.WaitForExit(5000) # Wait for 5 seconds (adjust as needed)
    Write-Host "Cmd Process Exited: $($proc.HasExited)"
    Write-Host "Cmd Exit Code: $($proc.ExitCode)"

    if ($proc.HasExited) {
        $errorMessage = $proc.StandardError.ReadToEnd()
        $standardOutput = $proc.StandardOutput.ReadToEnd() # Capture standard output
        if ($errorMessage) {
            Write-Error "Failed to start cmd.exe.  Error: $errorMessage"
        }
        else
        {
             Write-Error "Failed to start cmd.exe or it exited prematurely with no error message."
        }
        Write-Host "Cmd Standard Output: $standardOutput"
        #Remove-Item -Path $testDir -Recurse -Force  # Commented out for debugging
        #exit # Commented out for debugging
    }
}
catch {
    Write-Error "Exception while starting cmd.exe: $($_.Exception.Message)"
    #Remove-Item -Path $testDir -Recurse -Force # Commented out for debugging
    #exit # Commented out for debugging
}



# Check if cmd.exe is running
if ($proc -and -not $proc.HasExited) {
    Write-Host "Cmd started with PID: $($proc.Id), Path: $($proc.Path)"
    # Perform process hollowing on the launched process
    [ProcessHollowing]::SimulateHollowing($proc.Id)
}
else {
    Write-Error "Failed to start cmd.exe or it exited prematurely."
}



# Wait a moment for detection
Start-Sleep -Seconds 5

# Cleanup  # Commented out for debugging
#Get-Process cmd* | Stop-Process -Force -ErrorAction SilentlyContinue
#Remove-Item -Path $testDir -Recurse -Force # Commented out for debugging