# Code Generated by Sidekick is for learning and experimentation purposes only. 

# Define variables
$server = ""  # Replace with your server address
$username = ""  # Replace with your username
$password = ""  # Replace with your password
$jiraService = "jira"

# Function to run a command via SSH
function Run-SSHCommand($command) {
    $sshSession = New-SSHSession -ComputerName $server -Credential (New-Object PSCredential($username, (ConvertTo-SecureString $password -AsPlainText -Force)))
    $result = Invoke-SSHCommand -SessionId $sshSession.SessionId -Command $command
    Remove-SSHSession -SessionId $sshSession.SessionId
    return $result.Output
}

# Function to check Jira status
function Check-JiraStatus {
    $statusCommand = "sudo systemctl is-active $jiraService"
    return Run-SSHCommand $statusCommand
}

# Function to kill Java processes
function Kill-JavaProcesses {
    $killCommand = "sudo pkill -f java"
    Run-SSHCommand $killCommand
}

# Stop Jira service
Run-SSHCommand "sudo systemctl stop $jiraService"

# Check Jira status 3-4 times with 5 seconds interval
for ($i = 1; $i -le 4; $i++) {
    $status = Check-JiraStatus
    if ($status -eq "failed") {
        Write-Output "Jira has been successfully stopped."
        exit 0
    } elseif ($status -eq "active") {
        Write-Output "Jira is still running. Attempt $i of 4."
    } else {
        Write-Output "Unexpected status: $status. Please check Jira manually."
        exit 1
    }
    Start-Sleep -Seconds 5
}

# If the loop completes without stopping Jira, kill Java processes and try again
Write-Output "Could not stop Jira after multiple attempts. Attempting to kill Java processes..."
Kill-JavaProcesses

# Attempt to stop Jira again
Run-SSHCommand "sudo systemctl stop $jiraService"

# Check Jira status again
for ($i = 1; $i -le 4; $i++) {
    $status = Check-JiraStatus
    if ($status -eq "failed") {
        Write-Output "Jira has been successfully stopped after killing Java processes."
        exit 0
    } elseif ($status -eq "active") {
        Write-Output "Jira is still running after killing Java processes. Attempt $i of 4."
    } else {
        Write-Output "Unexpected status: $status. Please check Jira manually."
        exit 1
    }
    Start-Sleep -Seconds 5
}

# If Jira still cannot be stopped
Write-Output "Could not stop Jira after multiple attempts, even after killing Java processes. Please check manually."
#exit 1
