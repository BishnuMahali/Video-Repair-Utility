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
# - Interactive TUI & Emojis
# - Temp file testing
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

$directory = $PWD.Path
$useForceFix = $false
$deleteInstead = $false
$useRecurse = $false

# ================= INPUT UI WIZARD =================
Clear-Host
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " 🎬  ULTIMATE VIDEO REPAIR UTILITY  🎬 " -ForegroundColor White -BackgroundColor DarkBlue
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

function Ask-Question($prompt) {
    Write-Host $prompt -NoNewline -ForegroundColor Yellow
    Write-Host " (y/n): " -NoNewline -ForegroundColor DarkGray
    while ($true) {
        if ($Host.UI.RawUI.KeyAvailable) { $Host.UI.RawUI.FlushInputBuffer() }
        $keyInfo = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        $key = $keyInfo.Character.ToString().ToLower()
        if ($key -eq 'y') {
            Write-Host "Yes" -ForegroundColor Green
            return $true
        } elseif ($key -eq 'n') {
            Write-Host "No" -ForegroundColor Red
            return $false
        }
    }
}

# 1. Directory Selection
if (Ask-Question "📁 Change current directory? (Current: $directory)") {
    $directory = Select-Folder
    Write-Host "   Selected: $directory" -ForegroundColor Cyan
}

# 2. Subfolders
$useRecurse = Ask-Question "📂 Scan subfolders as well?"

# 3. Force Fix
$useForceFix = Ask-Question "🔥 Enable aggressive FORCE FIX if light fix fails?"

# 4. Action on Failure
if (Ask-Question "🗑️ Delete broken files instead of moving them to a folder?") {
    $deleteInstead = $true
} else {
    $deleteInstead = $false
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " Configuration Saved! " -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan

Clear-Host
Write-Host "🚀 Starting Scan..." -ForegroundColor Green

# ================= INIT =================
if (!(Test-Path "$directory\$brokenFolder")) {
    New-Item -ItemType Directory -Path "$directory\$brokenFolder" | Out-Null
}

if (Test-Path $cacheFile) {
    $processed = Get-Content $cacheFile | ConvertFrom-Json
    if ($processed.GetType().Name -eq "Object[]" -or $processed.GetType().Name -eq "PSCustomObject") {
        # Convert PSCustomObject to Hashtable
        $hash = @{}
        $processed.psobject.properties | ForEach-Object { $hash[$_.Name] = $_.Value }
        $processed = $hash
    }
} else {
    $processed = @{}
}

$allFiles = @()
foreach ($ext in $videoExtensions) {
    if ($useRecurse) {
        $allFiles += Get-ChildItem -Path $directory -Recurse -Filter $ext -File | Where-Object { $_.FullName -notmatch "\.tmp\." }
    } else {
        $allFiles += Get-ChildItem -Path $directory -Filter $ext -File | Where-Object { $_.FullName -notmatch "\.tmp\." }
    }
}

$total = $allFiles.Count
$count = 0

Write-Host "🔍 Found $total video files`n" -ForegroundColor Cyan

# Stats tracking
$stats = @{
    Total = $total
    OK = 0
    FixedLight = 0
    FixedForce = 0
    Failed = 0
    Ignored = 0
}

# ================= FUNCTIONS =================
function Test-Video($file) {
    if (!(Test-Path $file) -or (Get-Item $file).Length -eq 0) {
        return "File empty or not found"
    }
    
    # Fast Validation: ffprobe to check if it's even a valid media file
    $probeResult = & ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$file" 2>&1
    if ([string]::IsNullOrWhiteSpace($probeResult) -or $probeResult -match "Invalid data found") {
        return "Not a valid media file or fatally corrupted header"
    }

    # Fast Demuxing Test: -c copy skips decoding, improving performance exponentially
    $result = & ffmpeg -v error -i "$file" -c copy -f null - 2>&1
    return $result
}

function Fix-Video-Light($file) {
    $out = "$file.tmp.light.mp4"
    if (Test-Path $out) { Remove-Item $out -Force -ErrorAction SilentlyContinue }
    & ffmpeg -y -i "$file" -c copy "$out" 2>$null
    return $out
}

function Fix-Video-Force($file) {
    $out = "$file.tmp.force.mp4"
    if (Test-Path $out) { Remove-Item $out -Force -ErrorAction SilentlyContinue }
    & ffmpeg -y -err_detect ignore_err -i "$file" -c:v libx264 -c:a aac "$out" 2>$null
    return $out
}

function Safe-Log($msg) {
    Add-Content -Path $logFile -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $msg"
}

# ================= MAIN LOOP =================
foreach ($file in $allFiles) {
    $count++
    $filePath = $file.FullName
    $fileSize = $file.Length
    
    # Generate cache key combining path and size to detect changes
    $cacheKey = "$filePath|$fileSize"

    Write-Host "[$count/$total] ⏳ Processing: " -NoNewline -ForegroundColor Cyan
    Write-Host "$filePath" -ForegroundColor White

    if ($processed.ContainsKey($cacheKey)) {
        Write-Host "   ⏭️ Skipped (already processed)" -ForegroundColor DarkGray
        $stats.Ignored++
        continue
    }

    $errorMsg = Test-Video $filePath

    if (!$errorMsg) {
        Write-Host "   ✅ OK" -ForegroundColor Green
        $processed[$cacheKey] = "OK"
        $stats.OK++
        continue
    }

    Write-Host "   ⚠️ Errors detected. Attempting light fix..." -ForegroundColor Yellow
    $fixed = Fix-Video-Light $filePath

    if (!(Test-Video $fixed)) {
        Write-Host "   🛠️ Light fix successful" -ForegroundColor Green
        try {
            Move-Item -Path $fixed -Destination $filePath -Force -ErrorAction Stop
            $processed[$cacheKey] = "Fixed-Light"
            $stats.FixedLight++
        } catch {
            Write-Host "   ❌ Error replacing original file. Temp file left at $fixed" -ForegroundColor Red
            Safe-Log "Error replacing: $filePath. Exception: $($_.Exception.Message)"
        }
        continue
    }
    if (Test-Path $fixed) { Remove-Item $fixed -Force -ErrorAction SilentlyContinue }

    if ($useForceFix) {
        Write-Host "   🔥 Attempting FORCE fix..." -ForegroundColor Magenta
        $forced = Fix-Video-Force $filePath

        if (!(Test-Video $forced)) {
            Write-Host "   🛠️ Force fix successful" -ForegroundColor Green
            try {
                Move-Item -Path $forced -Destination $filePath -Force -ErrorAction Stop
                $processed[$cacheKey] = "Fixed-Force"
                $stats.FixedForce++
            } catch {
                Write-Host "   ❌ Error replacing original file. Temp file left at $forced" -ForegroundColor Red
                Safe-Log "Error replacing: $filePath. Exception: $($_.Exception.Message)"
            }
            continue
        }
        if (Test-Path $forced) { Remove-Item $forced -Force -ErrorAction SilentlyContinue }
    }

    Write-Host "   ❌ FAILED to repair" -ForegroundColor Red
    Safe-Log "Failed: $filePath"

    try {
        if ($deleteInstead) {
            Remove-Item $filePath -Force -ErrorAction Stop
            Write-Host "   🗑️ Deleted" -ForegroundColor Red
        } else {
            Move-Item $filePath "$directory\$brokenFolder" -Force -ErrorAction Stop
            Write-Host "   📁 Moved to Broken Files" -ForegroundColor Yellow
        }
        $processed[$cacheKey] = "Broken"
    } catch {
        Write-Host "   ❌ Error moving/deleting file. It might be locked." -ForegroundColor Red
        Safe-Log "Error moving/deleting: $filePath. Exception: $($_.Exception.Message)"
    }
    
    $stats.Failed++

    # Save progress after each file
    $processed | ConvertTo-Json -Depth 2 | Set-Content $cacheFile
}

# ================= SUMMARY =================
Write-Host "`n==========================================" -ForegroundColor Cyan
Write-Host " 📊 SUMMARY " -ForegroundColor White -BackgroundColor DarkBlue
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " 🔢 Total Scanned : $($stats.Total)"
Write-Host " ✅ OK            : $($stats.OK)" -ForegroundColor Green
Write-Host " ⏭️ Ignored       : $($stats.Ignored)" -ForegroundColor DarkGray
Write-Host " 🛠️ Light Fixed   : $($stats.FixedLight)" -ForegroundColor Cyan
Write-Host " 🔥 Force Fixed   : $($stats.FixedForce)" -ForegroundColor Magenta
Write-Host " ❌ Failed        : $($stats.Failed)" -ForegroundColor Red
Write-Host "==========================================" -ForegroundColor Cyan

Write-Host "`n📝 Log saved to " -NoNewline; Write-Host "$logFile" -ForegroundColor Yellow
Write-Host "💾 Cache saved to " -NoNewline; Write-Host "$cacheFile" -ForegroundColor Yellow
Write-Host "`nDone!" -ForegroundColor Green
