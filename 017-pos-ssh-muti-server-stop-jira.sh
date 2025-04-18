# Code Generated by Sidekick is for learning and experimentation purposes only. 

# Define variables
$servers = @(
    @{ Server = "app0012528l002.atrame.dummy.com"; Username = "app0012528l002.atrame.dummy.com"; Password = "app0012528l002.atrame.dummy.com" },
    @{ Server = "app0012528l002.atrame.dummy.com"; Username = "app0012528l002.atrame.dummy.com"; Password = "app0012528l002.atrame.dummy.com" }
    # Add more servers as needed
)
$jiraService = "jira"

# Function to run a command via SSH
function Run-SSHCommand($sshSession, $command) {
    try {
        $result = Invoke-SSHCommand -SessionId $sshSession.SessionId -Command $command
        return $result.Output
    } catch {
        Write-Error "Error occurred while executing command: $_"
        return $null
    }
}

# Function to check Jira status
function Check-JiraStatus($sshSession) {
    $statusCommand = "sudo systemctl is-active $jiraService"
    return Run-SSHCommand $sshSession $statusCommand
}

# Stop Jira service on multiple servers
foreach ($serverInfo in $servers) {
    $server = $serverInfo.Server
    $username = $serverInfo.Username
    $password = $serverInfo.Password

    try {
        $sshSession = New-SSHSession -ComputerName $server -Credential (New-Object PSCredential($username, (ConvertTo-SecureString $password -AsPlainText -Force)))
        Write-Output "SSH session secured successfully for $server."
    } catch {
        Write-Error "Failed to establish SSH session for $server."
        continue
    }

    $stopResult = Run-SSHCommand $sshSession "sudo systemctl stop $jiraService"

    if ($stopResult -eq $null) {
        Write-Output "Skipping further checks for $server due to command execution failure."
        Remove-SSHSession -SessionId $sshSession.SessionId
        continue
    }

    # Check Jira status 3-4 times with 5 seconds interval
    for ($i = 1; $i -le 4; $i++) {
        $status = Check-JiraStatus($sshSession)
        if ($status -eq "failed") {
            Write-Output "Jira has been successfully stopped on $server."
            break
        } elseif ($status -eq "active") {
            Write-Output "Jira is still running on $server. Attempt $i of 4."
        } else {
            Write-Output "Unexpected status on $server : $status. Please check Jira manually."
            break
        }
        Start-Sleep -Seconds 5
    }

    # If Jira still cannot be stopped
    if ($status -eq "active") {
        Write-Output "Could not stop Jira on $server after multiple attempts. Please check manually."
    }

    Remove-SSHSession -SessionId $sshSession.SessionId
}

Write-Output "Jira stop process completed on all servers."
exit 0
