<#
.SYNOPSIS
    Simulates a benign reverse shell connection to a user-specified host and port.

.DESCRIPTION
    This script attempts to establish a TCP connection to a remote host and port,
    simulating the network activity of a reverse shell.  It is intended for benign
    testing purposes only, such as verifying network detection capabilities.
    No malicious commands are executed.

.NOTES
    * Ensure you have a listening server (e.g., netcat) running on the specified
       host and port.
    * This script requires PowerShell version 3.0 or later.
#>

# --- Configuration ---
# Prompt the user for the remote host and port
$RemoteHost = Read-Host -Prompt "Enter the remote host IP or domain name (e.g., 127.0.0.1 or example.com)"
while (-not $RemoteHost) {
    $RemoteHost = Read-Host -Prompt "Host cannot be empty. Please enter the remote host IP or domain name"
}

$RemotePort = Read-Host -Prompt "Enter the remote port"
while ((-not $RemotePort) -or (-not ($RemotePort -match '^\d+$'))) {
    $RemotePort = Read-Host -Prompt "Port must be a number. Please enter the remote port"
}
$RemotePort = [int]$RemotePort # Convert the port to an integer

# --- Main Logic ---
try {
    # Attempt to establish a TCP connection
    $client = New-Object System.Net.Sockets.TCPClient
    Write-Host "[+] Attempting to connect to $($RemoteHost):$($RemotePort)..." -ForegroundColor Yellow
    $client.Connect($RemoteHost, $RemotePort)

    if ($client.Connected) {
        Write-Host "[+] Successfully established a benign connection to $($RemoteHost):$($RemotePort)" -ForegroundColor Green

        # Simulate sending benign data (optional)
        $stream = $client.GetStream()
        $writer = New-Object System.IO.StreamWriter($stream)
        $writer.WriteLine("This is a benign test connection from $($env:COMPUTERNAME).")
        $writer.Flush()

        Write-Host "[+] Sent benign test data." -ForegroundColor Cyan

        # Keep the connection open for a short duration (optional)
        Start-Sleep -Seconds 5

        # Close the connection
        $client.Close()
        Write-Host "[+] Connection closed." -ForegroundColor Cyan
    } else {
        Write-Warning "[-] Failed to establish a benign connection to $($RemoteHost):$($RemotePort)"
    }
} catch {
    Write-Error "[-] An error occurred: $_"
}
