# This script will check various locations that may be taking up space on a computer or server's drives.
# The results will be emailed using the specified email settings.

# Edit these variables
$computers = "computer1", "Server2", "morecomputernames", "example-server", "etc" # Add the computer names you want to check here.
$toAddresses = "example@contoso.com", "example2@contoso.com", "example3@contoso.com" # Add the email addresses you want to send the results to here.
$fromAddress = "example@contoso.com" # Change this to the email address you want to send the results from.
$emailSubject = "Storage Report" # Change this to the subject you want for the email.

$smtpAddress = "127.0.0.1" # Change this to your SMTP server address.
$smtp_port="2525" # Change this to your SMTP server port.

$lowSpaceThreshold = 3 # Change this to the threshold you want for low disk space in GB.

# Leave everything below this line
$emailContent = ""
$lowSpaceCount = 0

foreach ($computer in $computers) {
    # Start off email content with computer name
    $computer = $computer.toupper()
    $emailContent += "$($computer):`n"

    # Check free disk space
    $disks = Get-WmiObject -ComputerName $computer -Class Win32_LogicalDisk -Filter "DriveType = 3";
    foreach ($disk in $disks) {
        $freeSpaceGB = [math]::Round($disk.FreeSpace / 1GB, 2)
        # $freeSpaceGB = [Math]::Round([float]$disk.FreeSpace / 1073741824)  # This method only gets full GB values
        $deviceID = $disk.DeviceID

        # Check if the disk space is lower than 3GB and add to lowSpaceCount if yes
        if ($freeSpaceGB -lt $lowSpaceThreshold) {
            $lowSpaceCount++
            # Add each disk to email content with exclamation mark
            $emailContent += "!$($deviceID) has $($freeSpaceGB)GB free.`n"
        } else {
            # Add each disk to email content
            $emailContent += "$($deviceID) has $($freeSpaceGB)GB free.`n"
        }
    }

    # Check recycle bin used space
    $recycleBinItems = Get-ChildItem -Path "\\$($computer)\c$\`$Recycle.Bin" -Recurse -File -Force -ErrorAction SilentlyContinue
    if ($recycleBinItems) {
        # Calculate recycle bin size in GB
        $recycleBinSize = $recycleBinItems | Measure-Object -Property Length -Sum
        $recycleBinSizeGB = [math]::Round($recycleBinSize.Sum / 1GB, 2)

        # Add recycle bin size to email body
        $emailContent += "Recycle bin contents total size on C: drive: $recycleBinSizeGB GB`n"
    } else {
        $emailContent += "Recycle bin is empty on C: drive.`n"
    }

    # Check for crash dumps in each user's CrashDumps folder
    $userFolders = Get-ChildItem -Path "\\$($computer)\c$\Users" -Directory
    $totalCrashDumpSize = 0
    foreach ($userFolder in $userFolders) {
        $crashDumpFiles = Get-ChildItem -Path "\\$($computer)\c$\Users\$($userFolder.Name)\AppData\Local\CrashDumps" -File -ErrorAction SilentlyContinue # Get all the crash dump files
        if ($crashDumpFiles) {
            $crashDumpSize = $crashDumpFiles | Measure-Object -Property Length -Sum # Get the size of each users crash dumps
            $totalCrashDumpSize += [math]::Round($crashDumpSize.Sum / 1GB, 2) # Convert the size to GB and add to the total crash dump size
        }
    }
    $emailContent += "Total size of crash dumps found in C: drive: $totalCrashDumpSize GB`n" # Add the total to the email body

    # Check for dmp files in LiveKernelReports folder
    $dumpFiles = Get-ChildItem -Path "\\$($computer)\c$\Windows\LiveKernelReports" -File
    if ($dumpFiles) {
        $emailContent += "Files were found in C:\Windows\LiveKernelReports:`n"
        foreach ($file in $dumpFiles) {
            $emailContent += "  - File: $($file.Name), Size: $([math]::Round($file.Length / 1GB, 2)) GB`n"
        }
    } else {
        $emailContent += "No dmp files found in the LiveKernelReports folder.`n"
    }

    $emailContent += "`n`n"  # Add space after each server
}

# If there are any disks with less than the low space threshold, add an exclamation mark to the subject and add the amount of disks with low space to the beginning of the email
if ($lowSpaceCount -gt 0) {
    $emailSubject = "!" + $emailSubject
    $emailContent = "$lowSpaceCount disks have low space.`n`n" + $emailContent
}

# Create new email message
$smtp = New-Object Net.Mail.SmtpClient($smtpAddress, $smtp_port)
$msg = New-Object Net.Mail.MailMessage

# Add sender and recipient addresses
foreach ($address in $toAddresses) {
    $msg.To.Add($address)
}
$msg.From = $fromAddress  # Add from address
$msg.Subject = $emailSubject  # Add email subject
$msg.Body = $emailContent  # Add email content to the body
#$msg.IsBodyHtml = $true  # Enable HTML formatting for the body

$smtp.Send($msg)  # Send the email