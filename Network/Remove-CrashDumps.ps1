# This script will remove crash dumps from each user's profile on the specified computers.
# Use Measure-Storage.ps1 to check how much space the crash dumps are taking up.

# Edit these variables
$computers = "computer1", "Server2", "morecomputernames", "etc" # Add the computer names you want to check here.

# Leave everything below this line
foreach ($computer in $computers) {
    $userFolders = Get-ChildItem -Path "\\$($computer)\c$\Users" -Directory # Get all the user folders
    foreach ($userFolder in $userFolders) {
        Get-ChildItem -Path "\\$($computer)\c$\Users\$($userFolder.Name)\AppData\Local\CrashDumps" -File -ErrorAction SilentlyContinue | Remove-Item
        Write-Host "Removed crash dumps on $computer for $($userFolder.Name)."
    }
}