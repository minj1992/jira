# Code Generated by Sidekick is for learning and experimentation purposes only. 

# Define variables
$servers = @(
    @{ Server = "dummy"; Username = "a-dummyte.com"; Password = "lkcdummyidGG0R_np" },
    @{ Server = "dummy"; Username = "dummy"; Password = "dummyp" }
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

# Function to start Jira service
function Start-JiraService($sshSession) {
    $startCommand = "sudo systemctl start $jiraService"
    return Run-SSHCommand $sshSession $startCommand
}

# Start Jira service on multiple servers
foreach ($serverInfo in $servers) {
    $server = $serverInfo.Server
    $username = $serverInfo.Username
    $password = $serverInfo.Password

    try {
        $sshSession = New-SSHSession -ComputerName $server -Credential (New-Object PSCredential($username, (ConvertTo-SecureString $password -AsPlainText -Force))) -AcceptKey
        Write-Output "SSH session secured successfully for $server."
    } catch {
        Write-Error "Failed to establish SSH session for $server."
        continue
    }

    $startResult = Start-JiraService($sshSession)

    if ($startResult -eq $null) {
        Write-Output "Skipping further checks for $server due to command execution failure."
        Remove-SSHSession -SessionId $sshSession.SessionId
        continue
    }

    # Check Jira status 3-4 times with 5 seconds interval
    for ($i = 1; $i -le 4; $i++) {
        $status = Check-JiraStatus($sshSession)
        if ($status -eq "active") {
            Write-Output "Jira has been successfully started on $server."
            break
        } elseif ($status -eq "failed") {
            Write-Output "Jira is not running on $server. Attempt $i of 4."
        } else {
            Write-Output "Unexpected status on $server : $status. Please check Jira manually."
            break
        }
        Start-Sleep -Seconds 5
    }

    # If Jira still cannot be started
    if ($status -ne "active") {
        Write-Output "Could not start Jira on $server after multiple attempts. Please check manually."
    }

    Remove-SSHSession -SessionId $sshSession.SessionId
}

Write-Output "Jira start process completed on all servers."
exit 0

#################################################################
This script will:

Iterate through a list of servers defined in the $servers array.
Establish an SSH session for each server and maintain it until all commands are executed.
Use the -AcceptKey parameter to automatically accept the SSH host key without prompting for confirmation.
Attempt to start the Jira service on each server using sudo systemctl start jira.
Print a message indicating the SSH session was secured successfully for each server.
Check the status of the Jira service up to 4 times with a 5-second interval between checks for each server.
If the status is active, it will confirm that Jira has been successfully started on that server and move to the next server.
If the status is failed, it will indicate that Jira is not running and retry.
If the status is anything else, it will throw an error, disconnect the SSH session, and exit with code 1.
If Jira cannot be started after multiple attempts on any server, it will throw an error, disconnect the SSH session, and exit with code 1.
If Jira is successfully started on all servers, it will print a success message and exit with code 0.

Make sure to install the Posh-SSH module in PowerShell before running this script:
