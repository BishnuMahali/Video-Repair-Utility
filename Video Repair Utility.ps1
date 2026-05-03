# ==========================================
# Video Repair Utility (FFmpeg Required)
# ==========================================
# Features:
# - Scans directory recursively for video files
# - Verifies integrity using ffmpeg
# - Attempts non-aggressive fix first
# - Optional forced fix
# - Moves or deletes broken files
# - Resume support via cache
# - Safe stop with logs
# ==========================================

Add-Type -AssemblyName System.Windows.Forms

function Select-Folder {
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = "Select Directory to Scan"
    if ($dialog.ShowDialog() -eq "OK") {
        return $dialog.SelectedPath
    }
    return $PWD.Path
}

# ================= CONFIG =================
$videoExtensions = @("*.mp4","*.mkv","*.avi","*.mov","*.flv","*.wmv")
$cacheFile = "repair_cache.json"
$logFile = "repair_log.txt"
$brokenFolder = "Broken Files"

# ================= INPUT UI =================
Write-Host "\n==== VIDEO REPAIR TOOL ====\n"

$directory = $PWD.Path
Write-Host "Selected Directory: $directory"

$change = Read-Host "Change directory? (y/n)"
if ($change -eq "y") {
    $directory = Select-Folder
}

$useForceFix = Read-Host "Enable FORCE FIX? (y/n)"
$deleteInstead = Read-Host "Delete broken files instead of moving? (y/n)"

# ================= INIT =================
if (!(Test-Path "$directory\\$brokenFolder")) {
    New-Item -ItemType Directory -Path "$directory\\$brokenFolder" | Out-Null
}

if (Test-Path $cacheFile) {
    $processed = Get-Content $cacheFile | ConvertFrom-Json
} else {
    $processed = @{}
}

$allFiles = @()
foreach ($ext in $videoExtensions) {
    $allFiles += Get-ChildItem -Path $directory -Recurse -Filter $ext -File
}

$total = $allFiles.Count
$count = 0

Write-Host "\nFound $total video files\n"

# ================= FUNCTIONS =================
function Test-Video($file) {
    $result = & ffmpeg -v error -i "$file" -f null - 2>&1
    return $result
}

function Fix-Video-Light($file) {
    $out = "$file.fixed.mp4"
    & ffmpeg -y -i "$file" -c copy "$out" 2>$null
    return $out
}

function Fix-Video-Force($file) {
    $out = "$file.force.mp4"
    & ffmpeg -y -err_detect ignore_err -i "$file" -c:v libx264 -c:a aac "$out" 2>$null
    return $out
}

function Safe-Log($msg) {
    Add-Content -Path $logFile -Value "$(Get-Date) - $msg"
}

# ================= MAIN LOOP =================
foreach ($file in $allFiles) {
    $count++
    Write-Host "\n[$count/$total] Processing: $($file.FullName)"

    if ($processed.ContainsKey($file.FullName)) {
        Write-Host "Skipped (already processed)"
        continue
    }

    $error = Test-Video $file.FullName

    if (!$error) {
        Write-Host "OK"
        $processed[$file.FullName] = "OK"
        continue
    }

    Write-Host "Errors detected. Attempting light fix..."
    $fixed = Fix-Video-Light $file.FullName

    if (!(Test-Video $fixed)) {
        Write-Host "Light fix successful"
        Remove-Item $file.FullName
        Rename-Item $fixed $file.FullName
        $processed[$file.FullName] = "Fixed-Light"
        continue
    }

    if ($useForceFix -eq "y") {
        Write-Host "Attempting FORCE fix..."
        $forced = Fix-Video-Force $file.FullName

        if (!(Test-Video $forced)) {
            Write-Host "Force fix successful"
            Remove-Item $file.FullName
            Rename-Item $forced $file.FullName
            $processed[$file.FullName] = "Fixed-Force"
            continue
        }
    }

    Write-Host "FAILED to repair"
    Safe-Log "Failed: $($file.FullName)"

    if ($deleteInstead -eq "y") {
        Remove-Item $file.FullName
        Write-Host "Deleted"
    } else {
        Move-Item $file.FullName "$directory\\$brokenFolder"
        Write-Host "Moved to Broken Files"
    }

    $processed[$file.FullName] = "Broken"

    # Save progress after each file
    $processed | ConvertTo-Json | Set-Content $cacheFile
}

# ================= SUMMARY =================
Write-Host "\n==== SUMMARY ===="
$processed.GetEnumerator() | Group-Object Value | ForEach-Object {
    Write-Host "$($_.Name): $($_.Count)"
}

Write-Host "\nLog saved to $logFile"
Write-Host "Cache saved to $cacheFile"
