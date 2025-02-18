# This script will move files older than the specified number of days from the Downloads folder of each user profile to a network share.
# It will also create a folder for each user on the network share if it does not already exist.

# Edit these variables
$networkShare = "\\fc03\Downloads" # Change this to your network share path
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
                $destinationFolder = "$networkShare\$($profile.Name)"

                if (-not (Test-Path -Path $destinationFolder)) {
                  New-Item -ItemType Directory -Path $destinationFolder
                }

                Move-Item -Path $file.FullName -Destination $destinationFolder -Force
                Write-Host "Moved file: $($file.FullName)"
            }
        } catch {
            Write-Host "Failed to move files in folder: $fullPath. Error: $_"
        }
    } else {
        Write-Host "Folder does not exist: $fullPath"
    }
}