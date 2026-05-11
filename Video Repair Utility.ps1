# MIT License
# Copyright (c) 2026 Bishnu Mahali
# See LICENSE file in the repository root for full license text.

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

# ==========================================
# XAML UI DEFINITION
# ==========================================
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Ultimate Video Repair Utility" Height="750" Width="950" Background="#F4F4F9" WindowStartupLocation="CenterScreen">
    <Window.Resources>
        <Style x:Key="HeaderStyle" TargetType="TextBlock">
            <Setter Property="FontSize" Value="24"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="Foreground" Value="#2C3E50"/>
        </Style>
        <Style x:Key="SubHeaderStyle" TargetType="TextBlock">
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="Foreground" Value="#7F8C8D"/>
        </Style>
        <Style x:Key="CardStyle" TargetType="Border">
            <Setter Property="Background" Value="White"/>
            <Setter Property="CornerRadius" Value="10"/>
            <Setter Property="Padding" Value="20"/>
            <Setter Property="Margin" Value="0,0,0,20"/>
            <Setter Property="Effect">
                <Setter.Value>
                    <DropShadowEffect BlurRadius="15" Color="#D0D0D0" ShadowDepth="2" Opacity="0.4"/>
                </Setter.Value>
            </Setter>
        </Style>
        <Style x:Key="PrimaryButtonStyle" TargetType="Button">
            <Setter Property="Background" Value="#3498DB"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="Padding" Value="15,10"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Style.Resources>
                <Style TargetType="Border">
                    <Setter Property="CornerRadius" Value="5"/>
                </Style>
            </Style.Resources>
        </Style>
    </Window.Resources>

    <Grid Margin="30">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- Header -->
        <StackPanel Grid.Row="0" Margin="0,0,0,25">
            <TextBlock Text="VIDEO REPAIR PRO" Style="{StaticResource HeaderStyle}"/>
            <TextBlock Text="Automatic scan, verification, and restoration of corrupted media" Style="{StaticResource SubHeaderStyle}"/>
        </StackPanel>

        <!-- Main Content (Scrollable) -->
        <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto">
            <StackPanel>
                <!-- Directory Configuration -->
                <Border Style="{StaticResource CardStyle}">
                    <StackPanel>
                        <TextBlock Text="Scanning Directory" FontWeight="SemiBold" Margin="0,0,0,10" Foreground="#34495E"/>
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>
                            <TextBox x:Name="txtPath" Grid.Column="0" Height="35" VerticalContentAlignment="Center" Padding="10,0" IsReadOnly="True" Background="#FDFDFD" BorderBrush="#DCDDE1"/>
                            <Button x:Name="btnBrowse" Grid.Column="1" Content="Browse Folder" Width="120" Margin="10,0,0,0" Height="35" Cursor="Hand"/>
                        </Grid>
                        <StackPanel Orientation="Horizontal" Margin="0,15,0,0">
                            <CheckBox x:Name="chkRecurse" Content="Include Subfolders" IsChecked="False" VerticalAlignment="Center"/>
                            <CheckBox x:Name="chkDelete" Content="Delete broken files instead of moving" Margin="20,0,0,0" IsChecked="False" VerticalAlignment="Center" Foreground="#E74C3C"/>
                        </StackPanel>
                    </StackPanel>
                </Border>

                <!-- Processing Settings -->
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    
                    <!-- Codec & Hardware -->
                    <Border Style="{StaticResource CardStyle}" Grid.Column="0" Margin="0,0,10,20">
                        <StackPanel>
                            <TextBlock Text="Encoding Strategy" FontWeight="SemiBold" Margin="0,0,0,15" Foreground="#34495E"/>
                            
                            <TextBlock Text="Target Codec" FontSize="11" Foreground="#95A5A6" Margin="0,0,0,5"/>
                            <ComboBox x:Name="comboCodec" Height="30" Margin="0,0,0,15">
                                <ComboBoxItem Content="H.264 (Legacy/Standard)" IsSelected="True"/>
                                <ComboBoxItem Content="HEVC (H.265 / Efficiency)"/>
                                <ComboBoxItem Content="AV1 (Next-Gen)"/>
                            </ComboBox>

                            <TextBlock Text="Hardware Acceleration" FontSize="11" Foreground="#95A5A6" Margin="0,0,0,5"/>
                            <ComboBox x:Name="comboGpu" Height="30">
                                <ComboBoxItem Content="Auto-Detect (Recommended)" IsSelected="True"/>
                                <ComboBoxItem Content="CPU (Software)"/>
                                <ComboBoxItem Content="NVIDIA (NVENC)"/>
                                <ComboBoxItem Content="AMD (AMF)"/>
                                <ComboBoxItem Content="Intel (QSV)"/>
                            </ComboBox>
                        </StackPanel>
                    </Border>

                    <!-- Repair Mode -->
                    <Border Style="{StaticResource CardStyle}" Grid.Column="1" Margin="10,0,0,20">
                        <StackPanel>
                            <TextBlock Text="Repair Intensity" FontWeight="SemiBold" Margin="0,0,0,15" Foreground="#34495E"/>
                            
                            <RadioButton x:Name="rbStandard" Content="Standard (Header &amp; Container fix)" IsChecked="True" Margin="0,0,0,10">
                                <RadioButton.ToolTip>Attempts to fix index issues without re-encoding the whole file. Fast and safe.</RadioButton.ToolTip>
                            </RadioButton>
                            
                            <RadioButton x:Name="rbAggressive" Content="Aggressive (Full Stream Reconstruction)" Margin="0,0,0,10">
                                <RadioButton.ToolTip>Uses force-fix flags to reconstruct frames. Slower, as it re-encodes damaged sections.</RadioButton.ToolTip>
                            </RadioButton>

                            <TextBlock Text="Aggressive mode is recommended only if Standard fix fails." FontSize="11" FontStyle="Italic" Foreground="#7F8C8D" TextWrapping="Wrap" Margin="20,5,0,0"/>
                        </StackPanel>
                    </Border>
                </Grid>

                <!-- Progress Section -->
                <Border Style="{StaticResource CardStyle}">
                    <StackPanel>
                        <Grid Margin="0,0,0,10">
                            <TextBlock x:Name="lblProgressText" Text="Ready to scan" FontWeight="SemiBold" Foreground="#34495E"/>
                            <TextBlock x:Name="lblPercentage" HorizontalAlignment="Right" Text="0%" FontWeight="Bold" Foreground="#3498DB"/>
                        </Grid>
                        <ProgressBar x:Name="progressMain" Height="10" Minimum="0" Maximum="100" Value="0" Background="#ECF0F1" Foreground="#3498DB" BorderThickness="0"/>
                        
                        <Grid Margin="0,15,0,0">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="*"/>
                            </Grid.ColumnDefinitions>
                            <StackPanel Grid.Column="0">
                                <TextBlock Text="SUCCESS" FontSize="10" Foreground="#27AE60" FontWeight="Bold" HorizontalAlignment="Center"/>
                                <TextBlock x:Name="statSuccess" Text="0" FontSize="20" FontWeight="Bold" HorizontalAlignment="Center" Foreground="#2C3E50"/>
                            </StackPanel>
                            <StackPanel Grid.Column="1">
                                <TextBlock Text="FIXED" FontSize="10" Foreground="#2980B9" FontWeight="Bold" HorizontalAlignment="Center"/>
                                <TextBlock x:Name="statFixed" Text="0" FontSize="20" FontWeight="Bold" HorizontalAlignment="Center" Foreground="#2C3E50"/>
                            </StackPanel>
                            <StackPanel Grid.Column="2">
                                <TextBlock Text="FAILED" FontSize="10" Foreground="#E74C3C" FontWeight="Bold" HorizontalAlignment="Center"/>
                                <TextBlock x:Name="statFailed" Text="0" FontSize="20" FontWeight="Bold" HorizontalAlignment="Center" Foreground="#2C3E50"/>
                            </StackPanel>
                        </Grid>
                    </StackPanel>
                </Border>
                
                <!-- Log View -->
                <Border Background="#2C3E50" CornerRadius="5" Padding="10" Height="150" Margin="0,0,0,10">
                    <TextBox x:Name="txtLogs" Background="Transparent" Foreground="#ECF0F1" BorderThickness="0" 
                             IsReadOnly="True" VerticalScrollBarVisibility="Auto" TextWrapping="Wrap" FontFamily="Consolas" FontSize="11"/>
                </Border>
            </StackPanel>
        </ScrollViewer>

        <!-- Footer Actions -->
        <Grid Grid.Row="2" Margin="0,10,0,0">
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Left" VerticalAlignment="Center">
                <TextBlock Text="FFmpeg Status: " Foreground="#7F8C8D"/>
                <TextBlock x:Name="lblFfmpegStatus" Text="Checking..." FontWeight="Bold"/>
            </StackPanel>
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
                <Button x:Name="btnOpenBroken" Content="📂 Open Broken Folder" Margin="0,0,10,0" Padding="15,5" Background="Transparent" BorderBrush="#7F8C8D" Cursor="Hand"/>
                <Button x:Name="btnStart" Content="START REPAIR" Style="{StaticResource PrimaryButtonStyle}" Width="180"/>
            </StackPanel>
        </Grid>
    </Grid>
</Window>
"@

# ==========================================
# LOGIC & EVENTS
# ==========================================

# Load XAML
$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

# Control Mapping
$txtPath = $window.FindName("txtPath")
$btnBrowse = $window.FindName("btnBrowse")
$chkRecurse = $window.FindName("chkRecurse")
$chkDelete = $window.FindName("chkDelete")
$comboCodec = $window.FindName("comboCodec")
$comboGpu = $window.FindName("comboGpu")
$rbStandard = $window.FindName("rbStandard")
$rbAggressive = $window.FindName("rbAggressive")
$lblProgressText = $window.FindName("lblProgressText")
$lblPercentage = $window.FindName("lblPercentage")
$progressMain = $window.FindName("progressMain")
$statSuccess = $window.FindName("statSuccess")
$statFixed = $window.FindName("statFixed")
$statFailed = $window.FindName("statFailed")
$txtLogs = $window.FindName("txtLogs")
$lblFfmpegStatus = $window.FindName("lblFfmpegStatus")
$btnStart = $window.FindName("btnStart")
$btnOpenBroken = $window.FindName("btnOpenBroken")

# Global Config
$knownVideoExtensions = @(".mp4",".mkv",".avi",".mov",".flv",".wmv",".asf",".mpeg",".mpg",".webm",".vob",".mp4v",".m4v",".3gp",".3g2",".ts",".mts",".m2ts",".divx",".xvid",".f4v",".rmvb")
$brokenFolderName = "Broken Files"
$logFile = "repair_log.txt"
$cacheFile = "repair_cache.json"

$EncodersDict = @{
    "H.264" = @{CPU="libx264"; NVIDIA="h264_nvenc"; AMD="h264_amf"; Intel="h264_qsv"};
    "HEVC"  = @{CPU="libx265"; NVIDIA="hevc_nvenc"; AMD="hevc_amf"; Intel="hevc_qsv"};
    "AV1"   = @{CPU="libsvtav1"; NVIDIA="av1_nvenc"; AMD="av1_amf"; Intel="av1_qsv"}
}

# Initial State
$txtPath.Text = $PWD.Path

# ─────────────────────────────────────────────
# HELPER FUNCTIONS
# ─────────────────────────────────────────────

function Add-Log {
    param([string]$msg, [string]$type="INFO")
    $timestamp = Get-Date -Format "HH:mm:ss"
    $fullMsg = "[$timestamp] [$type] $msg"
    $window.Dispatcher.Invoke({
        $txtLogs.AppendText("$fullMsg`r`n")
        $txtLogs.ScrollToEnd()
    })
}

function Check-FFmpeg {
    $ffmpeg = Get-Command ffmpeg -ErrorAction SilentlyContinue
    $ffprobe = Get-Command ffprobe -ErrorAction SilentlyContinue
    if ($ffmpeg -and $ffprobe) {
        $lblFfmpegStatus.Text = "ACTIVE"
        $lblFfmpegStatus.Foreground = [System.Windows.Media.Brushes]::Green
        return $true
    } else {
        $lblFfmpegStatus.Text = "NOT FOUND"
        $lblFfmpegStatus.Foreground = [System.Windows.Media.Brushes]::Red
        Add-Log "FFmpeg or ffprobe not found in PATH! Repair will fail." "ERROR"
        return $false
    }
}

function Detect-Gpu($codec) {
    $vendors = @("NVIDIA", "AMD", "Intel")
    foreach ($vendor in $vendors) {
        $encoder = $EncodersDict[$codec][$vendor]
        $result = & ffmpeg -v error -f lavfi -i color=c=black:s=16x16:d=0.1 -c:v $encoder -f null - 2>$null
        if ($LASTEXITCODE -eq 0) {
            return @{Name=$vendor; Encoder=$encoder}
        }
    }
    return @{Name="CPU"; Encoder=$EncodersDict[$codec]["CPU"]}
}

function Test-Video-Health {
    param([string]$file)
    # Check if header is valid
    $probeResult = & ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$file" 2>&1
    if ([string]::IsNullOrWhiteSpace($probeResult) -or $probeResult -match "Invalid data found") {
        return "Corrupted Header"
    }

    # Demux test (fast check for stream errors)
    $result = & ffmpeg -v error -i "$file" -c copy -f null - 2>&1
    if ($result) { return "Stream Error: $result" }
    
    return $null # OK
}

# ─────────────────────────────────────────────
# EVENTS
# ─────────────────────────────────────────────

$btnBrowse.Add_Click({
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.SelectedPath = $txtPath.Text
    if ($dialog.ShowDialog() -eq "OK") {
        $txtPath.Text = $dialog.SelectedPath
        Add-Log "Target directory changed to: $($dialog.SelectedPath)"
    }
})

$btnOpenBroken.Add_Click({
    $path = Join-Path $txtPath.Text $brokenFolderName
    if (Test-Path $path) {
        explorer.exe $path
    } else {
        [System.Windows.MessageBox]::Show("Broken folder not found yet.", "Info")
    }
})

$btnStart.Add_Click({
    if (-not (Check-FFmpeg)) { return }

    # UI Locking
    $btnStart.IsEnabled = $false
    $btnBrowse.IsEnabled = $false
    
    $targetDir = $txtPath.Text
    $recurse = $chkRecurse.IsChecked
    $deleteBroken = $chkDelete.IsChecked
    $forceFix = $rbAggressive.IsChecked
    $codecName = $comboCodec.Text.Split(" ")[0] # Extract H.264, HEVC, etc.
    $gpuSelection = $comboGpu.Text
    
    # Background Processing
    $job = {
        param($dir, $recurse, $delete, $force, $codec, $gpuSel, $extensions, $brokenName, $encoders)

        $results = @{ Success=0; Fixed=0; Failed=0; Log="" }
        
        # 1. Hardware Setup
        $encoder = ""
        if ($gpuSel -match "Auto") {
            foreach ($v in @("NVIDIA", "AMD", "Intel")) {
                $enc = $encoders[$codec][$v]
                & ffmpeg -v error -f lavfi -i color=c=black:s=16x16:d=0.1 -c:v $enc -f null - 2>$null
                if ($LASTEXITCODE -eq 0) { $encoder = $enc; break }
            }
            if (-not $encoder) { $encoder = $encoders[$codec]["CPU"] }
        } elseif ($gpuSel -match "CPU") {
            $encoder = $encoders[$codec]["CPU"]
        } else {
            $vendor = $gpuSel.Split(" ")[0] # NVIDIA, AMD, etc.
            $encoder = $encoders[$codec][$vendor]
        }

        # 2. File Discovery
        $files = Get-ChildItem -Path $dir -File -Recurse:$recurse | Where-Object { $extensions -contains $_.Extension.ToLower() }
        $total = $files.Count
        $current = 0

        # Create broken folder if needed
        $brokenPath = Join-Path $dir $brokenName
        if (-not $delete -and -not (Test-Path $brokenPath)) { New-Item -ItemType Directory -Path $brokenPath | Out-Null }

        foreach ($file in $files) {
            $current++
            $relPath = $file.FullName.Replace($dir, "").TrimStart("\")
            
            # Progress update
            Write-Output @{ Type="Progress"; Current=$current; Total=$total; File=$relPath }

            # Health Check
            $probe = & ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$($file.FullName)" 2>&1
            if ([string]::IsNullOrWhiteSpace($probe) -or $probe -match "Invalid data found") {
                $isHealthy = $false
            } else {
                $demux = & ffmpeg -v error -i "$($file.FullName)" -c copy -f null - 2>&1
                $isHealthy = [string]::IsNullOrWhiteSpace($demux)
            }

            if ($isHealthy) {
                $results.Success++
                Write-Output @{ Type="Log"; Msg="OK: $relPath"; Severity="SUCCESS" }
                continue
            }

            # Repair Attempt 1: Light
            $tmpLight = "$($file.FullName).tmp.light.mp4"
            & ffmpeg -y -i "$($file.FullName)" -c copy "$tmpLight" 2>$null
            
            # Verify Light Fix
            $lightProbe = & ffprobe -v error -i "$tmpLight" 2>&1
            if ($LASTEXITCODE -eq 0) {
                Move-Item $tmpLight $file.FullName -Force
                $results.Fixed++
                Write-Output @{ Type="Log"; Msg="FIXED (Light): $relPath"; Severity="WARNING" }
                continue
            }
            if (Test-Path $tmpLight) { Remove-Item $tmpLight -Force }

            # Repair Attempt 2: Aggressive (if enabled)
            if ($force) {
                Write-Output @{ Type="Log"; Msg="Attempting Force repair: $relPath"; Severity="INFO" }
                $tmpForce = "$($file.FullName).tmp.force.mp4"
                & ffmpeg -y -err_detect ignore_err -fflags +genpts+discardcorrupt -async 1 -i "$($file.FullName)" -c:v $encoder -c:a aac "$tmpForce" 2>$null
                
                if ($LASTEXITCODE -eq 0) {
                    Move-Item $tmpForce $file.FullName -Force
                    $results.Fixed++
                    Write-Output @{ Type="Log"; Msg="FIXED (Aggressive): $relPath"; Severity="WARNING" }
                    continue
                }
                if (Test-Path $tmpForce) { Remove-Item $tmpForce -Force }
            }

            # Failure Handling
            $results.Failed++
            Write-Output @{ Type="Log"; Msg="FAILED: $relPath"; Severity="ERROR" }
            if ($delete) {
                Remove-Item $file.FullName -Force
            } else {
                Move-Item $file.FullName $brokenPath -Force
            }
        }

        Write-Output @{ Type="Done"; Results=$results }
    }

    $powershell = [PowerShell]::Create().AddScript($job).AddArgument($targetDir).AddArgument($recurse).AddArgument($deleteBroken).AddArgument($forceFix).AddArgument($codecName).AddArgument($gpuSelection).AddArgument($knownVideoExtensions).AddArgument($brokenFolderName).AddArgument($EncodersDict)
    
    $asyncResult = $powershell.BeginInvoke()

    # Simple Polling for GUI updates (keeping it simple for user)
    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromMilliseconds(100)
    $timer.Add_Tick({
        if ($asyncResult.IsCompleted) {
            $timer.Stop()
            $btnStart.IsEnabled = $true
            $btnBrowse.IsEnabled = $true
            $progressMain.Value = 100
            $lblPercentage.Text = "100%"
            $lblProgressText.Text = "Complete"
            Add-Log "All operations finished." "SUCCESS"
            return
        }

        $outputs = $powershell.Streams.Output | Select-Object -Last 10 # Get recent batches
        $powershell.Streams.Output.Clear()

        foreach ($out in $outputs) {
            if ($out.Type -eq "Progress") {
                $pct = [Math]::Round(($out.Current / $out.Total) * 100)
                $progressMain.Value = $pct
                $lblPercentage.Text = "$pct%"
                $lblProgressText.Text = "Processing: $($out.File)"
            } elseif ($out.Type -eq "Log") {
                Add-Log $out.Msg $out.Severity
            } elseif ($out.Type -eq "Done") {
                $statSuccess.Text = $out.Results.Success
                $statFixed.Text = $out.Results.Fixed
                $statFailed.Text = $out.Results.Failed
            }
        }
    })
    $timer.Start()
})

# Initial Checks
Check-FFmpeg
Add-Log "Utility Initialized. Ready for scan."

$window.ShowDialog() | Out-Null
