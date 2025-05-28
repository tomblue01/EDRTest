Add-Type -TypeDefinition @"
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;

public class MemoryDumper {
    [DllImport("kernel32.dll")]
    public static extern IntPtr OpenProcess(int dwDesiredAccess, bool bInheritHandle, int dwProcessId);
    
    [DllImport("kernel32.dll")]
    public static extern bool ReadProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, byte[] lpBuffer, int dwSize, out IntPtr lpNumberOfBytesRead);
    
    [DllImport("kernel32.dll")]
    public static extern bool CloseHandle(IntPtr hObject);
    
    public static void SimulateMemoryDump() {
        // Target a non-sensitive process for the test
        Process[] processes = Process.GetProcessesByName("notepad");
        if (processes.Length == 0) {
            System.Diagnostics.Process.Start("notepad.exe");
            // Use Start-Process and wait for it to start.  Important for reliable execution.
            System.Threading.Thread.Sleep(1000);
            processes = System.Diagnostics.Process.GetProcessesByName("notepad");
        }
        
        if (processes.Length == 0)
        {
            Console.WriteLine("Failed to start or find notepad process.");
            return;
        }
        
        int processId = processes[0].Id;
        Console.WriteLine("Target process (notepad) PID: " + processId);
        
        // Access constants
        const int PROCESS_VM_READ = 0x0010;
        const int PROCESS_QUERY_INFORMATION = 0x0400;
        
        IntPtr hProcess = OpenProcess(PROCESS_VM_READ | PROCESS_QUERY_INFORMATION, false, processId);
        Console.WriteLine("Process handle: " + hProcess);
        
        if (hProcess != IntPtr.Zero) {
            try {
                // Get base address of the process
                IntPtr baseAddress = processes[0].MainModule.BaseAddress;
                Console.WriteLine("Base address: " + baseAddress);
                
                // Try to read some memory
                byte[] buffer = new byte[1024];
                IntPtr bytesRead;
                bool success = ReadProcessMemory(hProcess, baseAddress, buffer, buffer.Length, out bytesRead);
                
                Console.WriteLine("Memory read: " + success + ", Bytes read: " + bytesRead);
                 if (success)
                 {
                    //Display the first 64 bytes of the buffer.  No need to show the whole 1024.
                    string hexDump = BitConverter.ToString(buffer, 0, 64).Replace("-", "");
                    Console.WriteLine("First 64 Bytes (Hex): " + hexDump);
                 }

            } finally {
                CloseHandle(hProcess);
                // Use Stop-Process in PowerShell
                System.Diagnostics.Process proc = System.Diagnostics.Process.GetProcessById(processId);
                if (proc != null)
                {
                   proc.Kill();
                }
                
            }
        }
    }
}
"@

# Call the function.
[MemoryDumper]::SimulateMemoryDump()