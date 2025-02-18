# This script will delete files older than the specified number of days from the Downloads folder of each user profile.

# Edit these variables
$olderThanThreshold = 30 # Change this to the number of days you want to use as the threshold

# Leave everything below this line
$userProfiles = Get-ChildItem "C:\Users" | Where-Object { $_.PSIsContainer } # Get all user profiles from the C:\Users directory

foreach ($profile in $userProfiles) {
    $fullPath = Join-Path -Path $profile.FullName -ChildPath "Downloads"
    if (Test-Path $fullPath) {
        try {
            $files = Get-ChildItem -Path $fullPath -Recurse | Where-Object { 
                -not $_.PSIsContainer -and $_.LastWriteTime -lt (Get-Date).AddDays($olderThanThreshold*-1)
            }
            foreach ($file in $files) {
                Remove-Item -Path $file.FullName -Force
                Write-Host "Deleted file: $($file.FullName)"
            }
        } catch {
            Write-Host "Failed to delete files in folder: $fullPath. Error: $_"
        }
    } else {
        Write-Host "Folder does not exist: $fullPath"
    }
}