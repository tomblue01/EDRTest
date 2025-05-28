@echo off
REM Batch Script to Modify File Permissions in C:\Windows\System32

REM IMPORTANT SECURITY WARNING:
REM Writing to C:\Windows\System32 requires elevated privileges and should be done with EXTREME CAUTION.
REM This script is a benign example for educational purposes only.
REM Running scripts with elevated privileges can have unintended consequences.
REM Ensure you understand each step before execution and test in a safe environment.

REM --- Configuration ---
set FileName=benign_test_file.txt
set FilePath=C:\Windows\System32\%FileName%
set AdministratorAccount=Administrator

REM --- Create the Benign Test File ---
echo This is a benign test file written to C:\Windows\System32. > %FilePath%
if %errorlevel% neq 0 (
    echo [!] Error creating file: %FilePath%
    exit /b 1
)
echo [+] Successfully created file: %FilePath%

REM --- Change Ownership to Administrator ---
takeown /F %FilePath% /A
if %errorlevel% neq 0 (
    echo [!] Error changing ownership.
    goto :end
)
echo [+] Ownership changed to: %AdministratorAccount%

REM --- Grant Administrator Delete and Write DAC Permissions ---
icacls %FilePath% /grant %AdministratorAccount%:(D,W)
if %errorlevel% neq 0 (
    echo [!] Error granting Administrator 'Delete' and 'Write' permissions.
    goto :end
)
echo [+] Granted Administrator 'Delete' and 'Write' permissions.

:end
echo [+] Script completed.