# Ultimate Video Repair Utility (WPF Edition)
# MIT License | Copyright (c) 2026 Bishnu Mahali

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

# ==========================================
# THEME ENGINE
# ==========================================
function Get-SystemTheme {
    try {
        $reg = Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" -ErrorAction SilentlyContinue
        if ($reg.AppsUseLightTheme -eq 0) { return "Dark" }
    } catch {}
    return "Light"
}

$CurrentTheme = Get-SystemTheme
$Theme = if ($CurrentTheme -eq "Dark") {
    @{ WindowBg="#1B1F23"; CardBg="#24292E"; TextMain="#E6EDF3"; TextSub="#8C959F"; Border="#30363D"; InputBg="#0D1117"; Primary="#3498DB"; Accent="#2980B9"; Shadow="#000000"; ProgressBg="#30363D"; Success="#27AE60"; Error="#E74C3C"; Warning="#F39C12"; Hover="#4AA3DF" }
} else {
    @{ WindowBg="#F4F4F9"; CardBg="#FFFFFF"; TextMain="#2C3E50"; TextSub="#7F8C8D"; Border="#DCDDE1"; InputBg="#FDFDFD"; Primary="#3498DB"; Accent="#2980B9"; Shadow="#D0D0D0"; ProgressBg="#ECF0F1"; Success="#27AE60"; Error="#E74C3C"; Warning="#F39C12"; Hover="#1B78B7" }
}

# ==========================================
# SETTINGS PERSISTENCE
# ==========================================
$global:ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$global:SettingsDir = Join-Path $ScriptDir ".Video Repair Utility"
$global:SettingsFile = Join-Path $SettingsDir "settings.json"

function Load-Settings {
    try {
        if (Test-Path $global:SettingsFile) {
            return Get-Content $global:SettingsFile -Raw | ConvertFrom-Json
        }
    } catch {}
    return $null
}

function Save-Settings {
    param($Settings)
    try {
        if (-not (Test-Path $global:SettingsDir)) {
            $d = New-Item -ItemType Directory -Path $global:SettingsDir -Force
            $d.Attributes = "Directory","Hidden"
        }
        $Settings | ConvertTo-Json | Set-Content $global:SettingsFile
    } catch {}
}

$savedSettings = Load-Settings

# ==========================================
# XAML UI DEFINITION
# ==========================================
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Ultimate Video Repair Utility" Height="900" Width="960" Background="$($Theme.WindowBg)" WindowStartupLocation="CenterScreen" MinWidth="800" MinHeight="700">
    <Window.Resources>
        <ControlTemplate x:Key="ComboBoxTemplate" TargetType="ComboBox">
            <Grid>
                <ToggleButton Name="ToggleButton" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" IsChecked="{Binding Path=IsDropDownOpen, Mode=TwoWay, RelativeSource={RelativeSource TemplatedParent}}" ClickMode="Press">
                    <ToggleButton.Template>
                        <ControlTemplate TargetType="ToggleButton">
                            <Border Name="Border" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="4">
                                <Grid HorizontalAlignment="Right" Width="24"><Path Name="Arrow" Fill="{TemplateBinding Foreground}" Data="M 0 0 L 4 4 L 8 0 Z" VerticalAlignment="Center" HorizontalAlignment="Center"/></Grid>
                            </Border>
                        </ControlTemplate>
                    </ToggleButton.Template>
                </ToggleButton>
                <ContentPresenter Name="ContentSite" IsHitTestVisible="False" Content="{TemplateBinding SelectionBoxItem}" ContentTemplate="{TemplateBinding SelectionBoxItemTemplate}" ContentTemplateSelector="{TemplateBinding ItemTemplateSelector}" Margin="10,3,30,3" VerticalAlignment="Center" HorizontalAlignment="Left" />
                <Popup Name="Popup" Placement="Bottom" IsOpen="{TemplateBinding IsDropDownOpen}" AllowsTransparency="True" Focusable="False" PopupAnimation="Slide">
                    <Grid Name="DropDown" SnapsToDevicePixels="True" MinWidth="{TemplateBinding ActualWidth}" MaxHeight="{TemplateBinding MaxDropDownHeight}"><Border Name="DropDownBorder" Background="$($Theme.InputBg)" BorderBrush="$($Theme.Border)" BorderThickness="1" CornerRadius="4"><ScrollViewer Margin="0" SnapsToDevicePixels="True"><StackPanel IsItemsHost="True" KeyboardNavigation.DirectionalNavigation="Contained" /></ScrollViewer></Border></Grid>
                </Popup>
            </Grid>
        </ControlTemplate>

        <ControlTemplate x:Key="CheckBoxTemplate" TargetType="CheckBox">
            <StackPanel Orientation="Horizontal">
                <Border Width="16" Height="16" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="1" Background="{TemplateBinding Background}" CornerRadius="2"><Path Name="CheckMark" Fill="{TemplateBinding Foreground}" Data="M 0 5 L 4 9 L 10 0" Visibility="Collapsed" Stroke="{TemplateBinding Foreground}" StrokeThickness="2" Margin="2" /></Border>
                <ContentPresenter Margin="8,0,0,0" VerticalAlignment="Center" />
            </StackPanel>
            <ControlTemplate.Triggers><Trigger Property="IsChecked" Value="True"><Setter TargetName="CheckMark" Property="Visibility" Value="Visible" /></Trigger></ControlTemplate.Triggers>
        </ControlTemplate>

        <Style TargetType="TextBlock"><Setter Property="Foreground" Value="$($Theme.TextMain)"/></Style>
        <Style TargetType="CheckBox"><Setter Property="Template" Value="{StaticResource CheckBoxTemplate}"/><Setter Property="Foreground" Value="$($Theme.TextMain)"/></Style>
        <Style TargetType="RadioButton"><Setter Property="Foreground" Value="$($Theme.TextMain)"/></Style>
        <Style TargetType="TextBox"><Setter Property="Background" Value="$($Theme.InputBg)"/><Setter Property="Foreground" Value="$($Theme.TextMain)"/><Setter Property="BorderBrush" Value="$($Theme.Border)"/><Setter Property="VerticalContentAlignment" Value="Center"/><Setter Property="Padding" Value="5"/></Style>
        <Style TargetType="ComboBox"><Setter Property="Template" Value="{StaticResource ComboBoxTemplate}" /><Setter Property="Background" Value="$($Theme.InputBg)"/><Setter Property="Foreground" Value="$($Theme.TextMain)"/><Setter Property="BorderBrush" Value="$($Theme.Border)"/><Setter Property="Height" Value="32"/></Style>
        <Style TargetType="ComboBoxItem"><Setter Property="Background" Value="Transparent"/><Setter Property="Foreground" Value="$($Theme.TextMain)"/><Setter Property="Padding" Value="10,6"/><Style.Triggers><Trigger Property="IsHighlighted" Value="True"><Setter Property="Background" Value="$($Theme.Accent)"/><Setter Property="Foreground" Value="White"/></Trigger></Style.Triggers></Style>
        <Style x:Key="CardStyle" TargetType="Border"><Setter Property="Background" Value="$($Theme.CardBg)"/><Setter Property="CornerRadius" Value="10"/><Setter Property="Padding" Value="20"/><Setter Property="Margin" Value="0,0,0,15"/><Setter Property="BorderBrush" Value="$($Theme.Border)"/><Setter Property="BorderThickness" Value="1"/><Setter Property="Effect"><Setter.Value><DropShadowEffect BlurRadius="15" Color="$($Theme.Shadow)" ShadowDepth="2" Opacity="0.4"/></Setter.Value></Setter></Style>
        <Style x:Key="PrimaryButtonStyle" TargetType="Button"><Setter Property="Background" Value="$($Theme.Primary)"/><Setter Property="Foreground" Value="White"/><Setter Property="FontWeight" Value="Bold"/><Setter Property="Padding" Value="15,10"/><Setter Property="BorderThickness" Value="0"/><Setter Property="Cursor" Value="Hand"/><Setter Property="Height" Value="45"/><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border Name="Border" Background="{TemplateBinding Background}" CornerRadius="5"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Border" Property="Background" Value="$($Theme.Hover)"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>
        <Style x:Key="StopButtonStyle" TargetType="Button"><Setter Property="Background" Value="$($Theme.Error)"/><Setter Property="Foreground" Value="White"/><Setter Property="FontWeight" Value="Bold"/><Setter Property="Padding" Value="15,10"/><Setter Property="BorderThickness" Value="0"/><Setter Property="Cursor" Value="Hand"/><Setter Property="Height" Value="45"/><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border Name="Border" Background="{TemplateBinding Background}" CornerRadius="5"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Border" Property="Background" Value="#C0392B"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>
        <Style x:Key="SecondaryButtonStyle" TargetType="Button"><Setter Property="Background" Value="$($Theme.InputBg)"/><Setter Property="Foreground" Value="$($Theme.TextMain)"/><Setter Property="BorderBrush" Value="$($Theme.Border)"/><Setter Property="BorderThickness" Value="1"/><Setter Property="Cursor" Value="Hand"/><Setter Property="Height" Value="35"/><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border Name="Border" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="4"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Border" Property="Background" Value="$($Theme.CardBg)"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>
    </Window.Resources>

    <Grid Margin="25">
        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
        <StackPanel Grid.Row="0" Margin="0,0,0,15"><TextBlock Text="VIDEO REPAIR PRO" FontWeight="Bold" FontSize="22"/><TextBlock Text="Automatic scan, verification, and restoration of corrupted media" Foreground="$($Theme.TextSub)" FontSize="13"/></StackPanel>
        <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto">
            <StackPanel>
                <!-- Card 1: Directory -->
                <Border Style="{StaticResource CardStyle}"><StackPanel><TextBlock Text="1. SCANNING DIRECTORY" FontWeight="SemiBold" Margin="0,0,0,10" Foreground="$($Theme.TextSub)"/><Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions><TextBox x:Name="txtPath" Grid.Column="0" Height="35" IsReadOnly="True"/><Button x:Name="btnBrowse" Grid.Column="1" Content="Browse" Width="100" Margin="10,0,0,0" Height="35" Style="{StaticResource SecondaryButtonStyle}"/></Grid><StackPanel Orientation="Horizontal" Margin="0,15,0,0"><CheckBox x:Name="chkRecurse" Content="Include Subfolders"/><CheckBox x:Name="chkDelete" Content="Delete broken files" Margin="20,0,0,0" Foreground="$($Theme.Error)"/></StackPanel></StackPanel></Border>

                <!-- Card 2+3: Strategy + Intensity -->
                <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                    <Border Style="{StaticResource CardStyle}" Grid.Column="0" Margin="0,0,10,15"><StackPanel><TextBlock Text="2. STRATEGY" FontWeight="SemiBold" Margin="0,0,0,15" Foreground="$($Theme.TextSub)"/><ComboBox x:Name="comboCodec" Height="30" Margin="0,0,0,15"><ComboBoxItem Content="H.264" IsSelected="True"/><ComboBoxItem Content="HEVC"/><ComboBoxItem Content="AV1"/></ComboBox><ComboBox x:Name="comboGpu" Height="30" Margin="0,0,0,8"/><TextBlock x:Name="lblEncoderInfo" Text="" FontSize="11" Foreground="$($Theme.TextSub)" Margin="0,5,0,0"/></StackPanel></Border>
                    <Border Style="{StaticResource CardStyle}" Grid.Column="1" Margin="10,0,0,15"><StackPanel><TextBlock Text="3. INTENSITY" FontWeight="SemiBold" Margin="0,0,0,15" Foreground="$($Theme.TextSub)"/><RadioButton x:Name="rbStandard" Content="Standard Fix" IsChecked="True" Margin="0,0,0,10"/><RadioButton x:Name="rbAggressive" Content="Aggressive Fix" Margin="0,0,0,10"/><TextBlock Text="VFR issues are always force-fixed&#10;regardless of intensity setting." FontSize="11" Foreground="$($Theme.TextSub)" Margin="0,5,0,0"/></StackPanel></Border>
                </Grid>

                <!-- Card 4: Session Options -->
                <Border Style="{StaticResource CardStyle}"><StackPanel><TextBlock Text="4. SESSION OPTIONS" FontWeight="SemiBold" Margin="0,0,0,10" Foreground="$($Theme.TextSub)"/><CheckBox x:Name="chkResume" Content="Enable Resume Functionality" IsChecked="True" Margin="0,0,0,8"/><CheckBox x:Name="chkCache" Content="Enable Cache for Faster Processing" IsChecked="True" Margin="0,0,0,8"/><CheckBox x:Name="chkLog" Content="Enable Log" IsChecked="True"/></StackPanel></Border>

                <!-- Card 5: Progress -->
                <Border Style="{StaticResource CardStyle}">
                    <StackPanel>
                        <Grid Margin="0,0,0,8">
                            <TextBlock x:Name="lblProgressText" Text="Ready"/>
                            <TextBlock x:Name="lblPercentage" HorizontalAlignment="Right" Text="0%" FontWeight="Bold" Foreground="$($Theme.Primary)" FontSize="14"/>
                        </Grid>
                        <ProgressBar x:Name="progressMain" Height="12" Background="$($Theme.ProgressBg)" Foreground="$($Theme.Primary)" BorderThickness="0"/>
                        <TextBlock x:Name="lblFileCount" Text="0 / 0 files" Foreground="$($Theme.TextSub)" FontSize="11" Margin="0,8,0,0"/>
                        <UniformGrid Columns="3" Margin="0,15,0,0">
                            <StackPanel><TextBlock Text="SUCCESS" FontSize="10" Foreground="$($Theme.Success)" FontWeight="Bold" HorizontalAlignment="Center"/><TextBlock x:Name="statSuccess" Text="0" FontSize="20" FontWeight="Bold" HorizontalAlignment="Center"/></StackPanel>
                            <StackPanel><TextBlock Text="FIXED" FontSize="10" Foreground="$($Theme.Accent)" FontWeight="Bold" HorizontalAlignment="Center"/><TextBlock x:Name="statFixed" Text="0" FontSize="20" FontWeight="Bold" HorizontalAlignment="Center"/></StackPanel>
                            <StackPanel><TextBlock Text="FAILED" FontSize="10" Foreground="$($Theme.Error)" FontWeight="Bold" HorizontalAlignment="Center"/><TextBlock x:Name="statFailed" Text="0" FontSize="20" FontWeight="Bold" HorizontalAlignment="Center"/></StackPanel>
                        </UniformGrid>
                    </StackPanel>
                </Border>

                <!-- Card 6: Log Console -->
                <Border Background="$($Theme.InputBg)" CornerRadius="5" Padding="10" Height="180" BorderBrush="$($Theme.Border)" BorderThickness="1"><TextBox x:Name="txtLogs" Background="Transparent" Foreground="$($Theme.TextMain)" BorderThickness="0" IsReadOnly="True" VerticalScrollBarVisibility="Auto" FontFamily="Consolas" FontSize="11" TextWrapping="Wrap"/></Border>
            </StackPanel>
        </ScrollViewer>
        <Grid Grid.Row="2" Margin="0,10,0,0">
            <StackPanel Orientation="Horizontal">
                <TextBlock Text="FFmpeg: "/><TextBlock x:Name="lblFfmpegStatus" Text="..." FontWeight="Bold"/>
                <TextBlock x:Name="lblElapsed" Text="" Margin="20,0,0,0" Foreground="$($Theme.TextSub)"/>
            </StackPanel>
            <Button x:Name="btnStart" Content="▶  START REPAIR" Style="{StaticResource PrimaryButtonStyle}" HorizontalAlignment="Right" Width="200"/>
        </Grid>
    </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $xaml; $window = [Windows.Markup.XamlReader]::Load($reader)
$txtPath=$window.FindName("txtPath"); $btnBrowse=$window.FindName("btnBrowse"); $chkRecurse=$window.FindName("chkRecurse"); $chkDelete=$window.FindName("chkDelete"); $comboCodec=$window.FindName("comboCodec"); $comboGpu=$window.FindName("comboGpu"); $lblEncoderInfo=$window.FindName("lblEncoderInfo"); $rbStandard=$window.FindName("rbStandard"); $rbAggressive=$window.FindName("rbAggressive"); $chkResume=$window.FindName("chkResume"); $chkCache=$window.FindName("chkCache"); $chkLog=$window.FindName("chkLog"); $lblProgressText=$window.FindName("lblProgressText"); $lblPercentage=$window.FindName("lblPercentage"); $progressMain=$window.FindName("progressMain"); $lblFileCount=$window.FindName("lblFileCount"); $statSuccess=$window.FindName("statSuccess"); $statFixed=$window.FindName("statFixed"); $statFailed=$window.FindName("statFailed"); $txtLogs=$window.FindName("txtLogs"); $lblFfmpegStatus=$window.FindName("lblFfmpegStatus"); $lblElapsed=$window.FindName("lblElapsed"); $btnStart=$window.FindName("btnStart")

$global:logEnabled=$false; $global:logFilePath=""
$global:isRunning=$false; $global:startTime=$null; $global:cancelRequested=$false
$knownVideoExtensions = @(".mp4",".mkv",".avi",".mov",".flv",".wmv",".asf",".mpeg",".mpg",".webm",".vob",".mp4v",".m4v",".3gp",".3g2",".ts",".mts",".m2ts",".divx",".xvid",".f4v",".rmvb")
$brokenFolderName = "Broken Files"
$EncodersDict = @{ "H.264" = @{CPU="libx264"; NVIDIA="h264_nvenc"; AMD="h264_amf"; Intel="h264_qsv"}; "HEVC" = @{CPU="libx265"; NVIDIA="hevc_nvenc"; AMD="hevc_amf"; Intel="hevc_qsv"}; "AV1" = @{CPU="libsvtav1"; NVIDIA="av1_nvenc"; AMD="av1_amf"; Intel="av1_qsv"} }

function Add-Log {
    param([string]$msg, [string]$type="INFO")
    $window.Dispatcher.Invoke({
        $ts = "[$(Get-Date -Format 'HH:mm:ss')] [$type] $msg"
        $txtLogs.AppendText("$ts`r`n")
        $txtLogs.ScrollToEnd()
        if ($global:logEnabled -and $global:logFilePath) {
            try { Add-Content -Path $global:logFilePath -Value $ts -ErrorAction SilentlyContinue } catch {}
        }
    })
}

function Check-FFmpeg {
    if (Get-Command ffmpeg -ErrorAction SilentlyContinue) {
        $lblFfmpegStatus.Text = "ACTIVE"
        $lblFfmpegStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($Theme.Success)
        return $true
    }
    $lblFfmpegStatus.Text = "MISSING"
    $lblFfmpegStatus.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($Theme.Error)
    return $false
}

function Update-GpuList {
    $codecName=$comboCodec.Text.Split(" ")[0]; $ffmpegEncoders=(ffmpeg -encoders 2>&1 | Out-String); $comboGpu.Items.Clear()
    foreach ($vendor in @("CPU", "NVIDIA", "AMD", "Intel")) {
        $encoder=$EncodersDict[$codecName][$vendor]; $color="#6E7781"; $status="Not Supported"
        if ($vendor -eq "CPU") { $supported=$true; $color=$Theme.Success; $status="Confirmed" }
        elseif ($ffmpegEncoders -match "\b$encoder\b") {
            $dummy=@("-v","error","-f","lavfi","-i","color=black:s=1280x720:r=24","-pix_fmt","yuv420p","-vframes","1","-c:v",$encoder,"-f","null","-")
            $null = & ffmpeg @dummy 2>&1
            if ($LASTEXITCODE -eq 0) { $supported=$true; $color=$Theme.Success; $status="Confirmed" } else { $supported=$false; $color=$Theme.Warning; $status="Init Failed" }
        }
        $item=New-Object System.Windows.Controls.ComboBoxItem; $stack=New-Object System.Windows.Controls.StackPanel; $stack.Orientation="Horizontal"
        $circle=New-Object System.Windows.Controls.Border; $circle.Width=10; $circle.Height=10; $circle.CornerRadius=5; $circle.Margin="0,0,10,0"; $circle.Background=[System.Windows.Media.BrushConverter]::new().ConvertFromString($color)
        $text=New-Object System.Windows.Controls.TextBlock; $text.Text=$vendor; $text.Foreground=[System.Windows.Media.BrushConverter]::new().ConvertFromString($Theme.TextMain)
        $stack.Children.Add($circle); $stack.Children.Add($text); $item.Content=$stack; $item.Tag=$encoder; $item.ToolTip=$status; $comboGpu.Items.Add($item)
    }
    $comboGpu.SelectedIndex = 0
    Update-EncoderInfo
}

function Update-EncoderInfo {
    if ($comboGpu.SelectedItem -ne $null) {
        $tag = $comboGpu.SelectedItem.Tag
        $tip = $comboGpu.SelectedItem.ToolTip
        $lblEncoderInfo.Text = "Encoder: $tag — $tip"
    }
}

function Save-CurrentSettings {
    $gpu_vendor = "CPU"
    if ($comboGpu.SelectedItem -ne $null) {
        $content = $comboGpu.SelectedItem.Content
        if ($content -is [System.Windows.Controls.StackPanel]) {
            foreach ($child in $content.Children) {
                if ($child -is [System.Windows.Controls.TextBlock]) { $gpu_vendor = $child.Text; break }
            }
        }
    }
    $settings = @{
        directory = $txtPath.Text
        codec = $comboCodec.Text.Split(" ")[0]
        gpu = $gpu_vendor
        intensity = if ($rbAggressive.IsChecked) { "aggressive" } else { "standard" }
        recurse = [bool]$chkRecurse.IsChecked
        delete = [bool]$chkDelete.IsChecked
        resume = [bool]$chkResume.IsChecked
        cache = [bool]$chkCache.IsChecked
        log = [bool]$chkLog.IsChecked
    }
    Save-Settings $settings
}

function Apply-SavedSettings {
    if ($null -eq $savedSettings) { return }
    try {
        if ($savedSettings.directory -and (Test-Path $savedSettings.directory -PathType Container)) { $txtPath.Text = $savedSettings.directory }
        if ($savedSettings.codec) {
            foreach ($item in $comboCodec.Items) {
                if ($item.Content -eq $savedSettings.codec) { $comboCodec.SelectedItem = $item; break }
            }
            Update-GpuList
        }
        if ($savedSettings.gpu) {
            for ($i=0; $i -lt $comboGpu.Items.Count; $i++) {
                $content = $comboGpu.Items[$i].Content
                if ($content -is [System.Windows.Controls.StackPanel]) {
                    foreach ($child in $content.Children) {
                        if ($child -is [System.Windows.Controls.TextBlock] -and $child.Text -eq $savedSettings.gpu) {
                            $comboGpu.SelectedIndex = $i; break
                        }
                    }
                }
            }
            Update-EncoderInfo
        }
        if ($savedSettings.intensity -eq "aggressive") { $rbAggressive.IsChecked = $true } else { $rbStandard.IsChecked = $true }
        if ($null -ne $savedSettings.recurse) { $chkRecurse.IsChecked = $savedSettings.recurse }
        if ($null -ne $savedSettings.delete) { $chkDelete.IsChecked = $savedSettings.delete }
        if ($null -ne $savedSettings.resume) { $chkResume.IsChecked = $savedSettings.resume }
        if ($null -ne $savedSettings.cache) { $chkCache.IsChecked = $savedSettings.cache }
        if ($null -ne $savedSettings.log) { $chkLog.IsChecked = $savedSettings.log }
    } catch {}
}

$txtPath.Text=$PWD.Path; Check-FFmpeg; Update-GpuList; Apply-SavedSettings
$btnBrowse.Add_Click({ Add-Type -AssemblyName System.Windows.Forms; $dialog=New-Object System.Windows.Forms.FolderBrowserDialog; $dialog.SelectedPath=$txtPath.Text; if ($dialog.ShowDialog() -eq "OK") { $txtPath.Text=$dialog.SelectedPath } })
$comboCodec.Add_SelectionChanged({ Update-GpuList })
$comboGpu.Add_SelectionChanged({ Update-EncoderInfo })
$chkResume.Add_Click({ if ($chkResume.IsChecked) { $chkCache.IsChecked=$true } }); $chkCache.Add_Click({ if (-not $chkCache.IsChecked) { $chkResume.IsChecked=$false } })

function Set-UIState {
    param([bool]$running)
    $window.Dispatcher.Invoke({
        $state = if ($running) { $false } else { $true }
        $btnBrowse.IsEnabled = $state
        $comboCodec.IsEnabled = $state
        $comboGpu.IsEnabled = $state
        $chkRecurse.IsEnabled = $state
        $chkDelete.IsEnabled = $state
        $chkResume.IsEnabled = $state
        $chkCache.IsEnabled = $state
        $chkLog.IsEnabled = $state
        $rbStandard.IsEnabled = $state
        $rbAggressive.IsEnabled = $state
        if ($running) {
            $btnStart.Content = "⏹  STOP"
            $btnStart.Style = $window.Resources["StopButtonStyle"]
        } else {
            $btnStart.Content = "▶  START REPAIR"
            $btnStart.Style = $window.Resources["PrimaryButtonStyle"]
        }
    })
}

$btnStart.Add_Click({
    if ($global:isRunning) {
        # Stop requested
        $global:cancelRequested = $true
        Add-Log "Cancelling..." "WARNING"
        return
    }

    if (-not (Check-FFmpeg)) { return }
    Save-CurrentSettings

    # Reset UI
    $statSuccess.Text = "0"; $statFixed.Text = "0"; $statFailed.Text = "0"
    $progressMain.Value = 0; $lblPercentage.Text = "0%"; $lblFileCount.Text = "Scanning..."
    $lblProgressText.Text = "Scanning for video files..."
    $txtLogs.Clear()

    $global:isRunning = $true
    $global:cancelRequested = $false
    $global:startTime = [DateTime]::Now
    $global:logEnabled = $chkLog.IsChecked

    Set-UIState $true

    $workDir=Join-Path $txtPath.Text ".Video Repair Utility"
    if ($chkCache.IsChecked -or $chkLog.IsChecked) {
        if (-not (Test-Path $workDir)) { $hd=New-Item -ItemType Directory -Path $workDir -Force; $hd.Attributes="Directory","Hidden" }
    }
    $cacheFile=Join-Path $workDir "Cache.json"; $global:logFilePath=Join-Path $workDir "Log.txt"
    $cache=@{}
    if ($chkResume.IsChecked -and (Test-Path $cacheFile)) {
        try { $json=Get-Content $cacheFile -Raw | ConvertFrom-Json; foreach($e in $json){ if($e.Path){$cache[$e.Path.ToLowerInvariant()]=$e} } } catch {}
    }

    $config=@{
        Dir=$txtPath.Text; Recurse=$chkRecurse.IsChecked; Delete=$chkDelete.IsChecked
        Force=$rbAggressive.IsChecked; Encoder=$comboGpu.SelectedItem.Tag
        CodecName=$comboCodec.Text.Split(" ")[0]
        Exts=$knownVideoExtensions; BrokenName=$brokenFolderName
        CacheEnabled=$chkCache.IsChecked; CacheFile=$cacheFile; Cache=$cache
        ResumeEnabled=$chkResume.IsChecked
    }

    $job={ param($config)
        $results=@{ Success=0; Fixed=0; Failed=0; Skipped=0 }
        $cpuEncoder = @{ "H.264"="libx264"; "HEVC"="libx265"; "AV1"="libsvtav1" }[$config.CodecName]

        $files=Get-ChildItem -Path $config.Dir -File -Recurse:$config.Recurse | Where-Object { $config.Exts -contains $_.Extension.ToLower() }
        $total=$files.Count; $current=0

        Write-Output @{ Type="Log"; Msg="Found $total video file(s)"; Sev="INFO" }

        if ($total -eq 0) {
            Write-Output @{ Type="Log"; Msg="No video files found in the selected directory."; Sev="WARNING" }
            Write-Output @{ Type="Done"; Results=$results }
            return
        }

        $brokenPath=Join-Path $config.Dir $config.BrokenName
        if (-not $config.Delete -and -not (Test-Path $brokenPath)) { New-Item -ItemType Directory -Path $brokenPath | Out-Null }

        foreach ($file in $files) {
            $current++; $key=$file.FullName.ToLowerInvariant(); $sig="$($file.Length)|$($file.LastWriteTimeUtc.Ticks)"
            Write-Output @{ Type="Progress"; Current=$current; Total=$total; File=$file.Name }

            # Resume check
            if ($config.ResumeEnabled -and $config.Cache.ContainsKey($key)) {
                if ($config.Cache[$key].Signature -eq $sig) {
                    Write-Output @{ Type="Log"; Msg="Cached Skip: $($file.Name)"; Sev="INFO" }
                    $results.Skipped++; Write-Output @{ Type="Stat"; Results=$results }
                    continue
                }
            }

            $isBroken = $false; $codecMissing = $false; $isVFR = $false

            # Codec mismatch check
            if (@(".avi", ".wmv", ".flv", ".vob", ".ts", ".mpg", ".mpeg", ".m2ts", ".mts") -contains $file.Extension.ToLower()) {
                $codecName = & ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$($file.FullName)" 2>&1
                if ($codecName -match "rawvideo") { $codecMissing = $true; $isBroken = $true }
            }

            # VFR check
            if (-not $isBroken) {
                $vfr_check = & ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate,avg_frame_rate -of default=noprint_wrappers=1:nokey=1 "$($file.FullName)" 2>&1
                if (-not [string]::IsNullOrWhiteSpace($vfr_check)) {
                    $rates = $vfr_check -split "`n" | Where-Object { $_.Trim() -ne "" }
                    if ($rates.Count -ge 2) {
                        try {
                            $r1 = if ($rates[0].Trim() -match "/") { [double]$rates[0].Trim().Split('/')[0] / [double]$rates[0].Trim().Split('/')[1] } else { [double]$rates[0].Trim() }
                            $r2 = if ($rates[1].Trim() -match "/") { [double]$rates[1].Trim().Split('/')[0] / [double]$rates[1].Trim().Split('/')[1] } else { [double]$rates[1].Trim() }
                            if ([Math]::Abs($r1 - $r2) -gt 0.1) {
                                $isVFR = $true; $isBroken = $true
                                Write-Output @{ Type="Log"; Msg="VFR/Timestamp jitter detected: $($file.Name)"; Sev="WARNING" }
                            }
                        } catch {}
                    }
                }
            }

            # Demuxing test
            if (-not $isBroken) {
                $demux = & ffmpeg -v error -i "$($file.FullName)" -c copy -f null - 2>&1
                if (-not [string]::IsNullOrWhiteSpace($demux)) { $isBroken = $true }
            }

            if (-not $isBroken) {
                $results.Success++; Write-Output @{ Type="Log"; Msg="OK: $($file.Name)"; Sev="SUCCESS" }
                Write-Output @{ Type="Stat"; Results=$results }
                continue
            }

            $fixed = $false

            # Strategy 1: Codec recovery
            if ($codecMissing) {
                Write-Output @{ Type="Log"; Msg="Codec missing. Attempting recovery: $($file.Name)"; Sev="WARNING" }
                $tmp="$($file.FullName).tmp.mp4"
                & ffmpeg -y -loglevel error -c:v hevc -i "$($file.FullName)" -c copy -movflags +faststart "$tmp" 2>$null
                if ($LASTEXITCODE -ne 0) { & ffmpeg -y -loglevel error -c:v av1 -i "$($file.FullName)" -c copy -movflags +faststart "$tmp" 2>$null }
                if ($LASTEXITCODE -eq 0 -and (Test-Path $tmp)) {
                    $newFile = [System.IO.Path]::ChangeExtension($file.FullName, ".mp4")
                    if ((Test-Path $newFile) -and ($newFile -ne $file.FullName)) { Remove-Item $newFile -Force }
                    Move-Item $tmp $newFile -Force
                    if ($newFile -ne $file.FullName) { if ($config.Delete) { Remove-Item $file.FullName -Force } else { Move-Item $file.FullName $brokenPath -Force } }
                    $results.Fixed++; $fixed = $true
                    Write-Output @{ Type="Log"; Msg="CODEC RECOVERED: $($file.Name)"; Sev="SUCCESS" }
                    if ($config.CacheEnabled) { $config.Cache[$key]=@{Path=$file.FullName; Signature=$sig; Status="Processed"}; $config.Cache.Values | ConvertTo-Json -Depth 4 | Set-Content $config.CacheFile }
                } else {
                    if (Test-Path $tmp) { Remove-Item $tmp -Force }
                }
            }

            # Strategy 2: VFR Force Fix (always re-encode for VFR)
            if (-not $fixed -and $isVFR) {
                Write-Output @{ Type="Log"; Msg="VFR detected, forcing re-encode: $($file.Name)"; Sev="INFO" }
                $bitrateStr = & ffprobe -v error -show_entries format=bit_rate -of default=noprint_wrappers=1:nokey=1 "$($file.FullName)" 2>&1
                if ($bitrateStr -match '^\d+$') { $bflag = "$([Math]::Round([double]$bitrateStr * 1.2))" } else { $bflag = "20M" }

                # Get framerate for CFR enforcement
                $fpsStr = & ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of default=noprint_wrappers=1:nokey=1 "$($file.FullName)" 2>&1
                $fpsInt = 30
                try { if ($fpsStr -match "/") { $fpsInt = [Math]::Round([double]$fpsStr.Split('/')[0] / [double]$fpsStr.Split('/')[1]) } else { $fpsInt = [Math]::Round([double]$fpsStr) } } catch { $fpsInt = 30 }

                $tmp="$($file.FullName).tmp.mp4"
                $encToUse = $config.Encoder
                & ffmpeg -y -err_detect ignore_err -fflags +genpts+discardcorrupt -async 1 -i "$($file.FullName)" -fps_mode cfr -r $fpsInt -c:v $encToUse -b:v $bflag -c:a aac -b:a 320k "$tmp" 2>$null
                if ($LASTEXITCODE -ne 0 -and $encToUse -ne $cpuEncoder) {
                    Write-Output @{ Type="Log"; Msg="GPU encoder failed, falling back to CPU ($cpuEncoder)"; Sev="WARNING" }
                    & ffmpeg -y -err_detect ignore_err -fflags +genpts+discardcorrupt -async 1 -i "$($file.FullName)" -fps_mode cfr -r $fpsInt -c:v $cpuEncoder -b:v $bflag -c:a aac -b:a 320k "$tmp" 2>$null
                }
                if ($LASTEXITCODE -eq 0 -and (Test-Path $tmp)) {
                    Move-Item $tmp $file.FullName -Force; $results.Fixed++; $fixed = $true
                    Write-Output @{ Type="Log"; Msg="VFR FIXED: $($file.Name)"; Sev="SUCCESS" }
                } else {
                    if (Test-Path $tmp) { Remove-Item $tmp -Force }
                    Write-Output @{ Type="Log"; Msg="VFR fix failed: $($file.Name)"; Sev="ERROR" }
                }
                if ($config.CacheEnabled) { $config.Cache[$key]=@{Path=$file.FullName; Signature=$sig; Status="Processed"}; $config.Cache.Values | ConvertTo-Json -Depth 4 | Set-Content $config.CacheFile }
            }

            # Strategy 3+4: Light or Force fix based on setting
            if (-not $fixed) {
                if ($config.Force) {
                    Write-Output @{ Type="Log"; Msg="Attempting force fix: $($file.Name)"; Sev="INFO" }
                    $bitrateStr = & ffprobe -v error -show_entries format=bit_rate -of default=noprint_wrappers=1:nokey=1 "$($file.FullName)" 2>&1
                    if ($bitrateStr -match '^\d+$') { $bflag = "$([Math]::Round([double]$bitrateStr * 1.2))" } else { $bflag = "20M" }
                    $tmp="$($file.FullName).tmp.mp4"
                    $encToUse = $config.Encoder
                    & ffmpeg -y -err_detect ignore_err -fflags +genpts+discardcorrupt -async 1 -i "$($file.FullName)" -c:v $encToUse -b:v $bflag -c:a aac -b:a 320k "$tmp" 2>$null
                    if ($LASTEXITCODE -ne 0 -and $encToUse -ne $cpuEncoder) {
                        Write-Output @{ Type="Log"; Msg="GPU encoder failed, falling back to CPU ($cpuEncoder)"; Sev="WARNING" }
                        & ffmpeg -y -err_detect ignore_err -fflags +genpts+discardcorrupt -async 1 -i "$($file.FullName)" -c:v $cpuEncoder -b:v $bflag -c:a aac -b:a 320k "$tmp" 2>$null
                    }
                } else {
                    Write-Output @{ Type="Log"; Msg="Attempting light fix: $($file.Name)"; Sev="INFO" }
                    $tmp="$($file.FullName).tmp.mp4"
                    & ffmpeg -y -i "$($file.FullName)" -c copy "$tmp" 2>$null
                }
                if ($LASTEXITCODE -eq 0 -and (Test-Path $tmp)) {
                    Move-Item $tmp $file.FullName -Force; $results.Fixed++; $fixed = $true
                    Write-Output @{ Type="Log"; Msg="FIXED: $($file.Name)"; Sev="SUCCESS" }
                } else {
                    if (Test-Path $tmp) { Remove-Item $tmp -Force }
                }
                if ($config.CacheEnabled) { $config.Cache[$key]=@{Path=$file.FullName; Signature=$sig; Status="Processed"}; $config.Cache.Values | ConvertTo-Json -Depth 4 | Set-Content $config.CacheFile }
            }

            # All strategies failed
            if (-not $fixed) {
                $results.Failed++
                Write-Output @{ Type="Log"; Msg="FAILED: $($file.Name)"; Sev="ERROR" }
                if ($config.Delete) { Remove-Item $file.FullName -Force }
                else {
                    $dest = Join-Path $brokenPath $file.Name
                    if (Test-Path $dest) { $dest = Join-Path $brokenPath "$([System.IO.Path]::GetFileNameWithoutExtension($file.Name))_$([int](Get-Date -UFormat %s))$($file.Extension)" }
                    Move-Item $file.FullName $dest -Force
                }
                if ($config.CacheEnabled) { $config.Cache[$key]=@{Path=$file.FullName; Signature=$sig; Status="Processed"}; $config.Cache.Values | ConvertTo-Json -Depth 4 | Set-Content $config.CacheFile }
            }

            Write-Output @{ Type="Stat"; Results=$results }
        }
        Write-Output @{ Type="Done"; Results=$results }
    }

    $powershell=[PowerShell]::Create().AddScript($job).AddArgument($config); $asyncResult=$powershell.BeginInvoke()

    # Elapsed timer
    $elapsedTimer=New-Object System.Windows.Threading.DispatcherTimer; $elapsedTimer.Interval=[TimeSpan]::FromSeconds(1)
    $elapsedTimer.Add_Tick({
        if ($global:startTime -ne $null) {
            $elapsed = [DateTime]::Now - $global:startTime
            $lblElapsed.Text = "Elapsed: $($elapsed.ToString('mm\:ss'))"
            if ($elapsed.TotalHours -ge 1) { $lblElapsed.Text = "Elapsed: $($elapsed.ToString('hh\:mm\:ss'))" }
        }
    })
    $elapsedTimer.Start()

    # Main polling timer
    $timer=New-Object System.Windows.Threading.DispatcherTimer; $timer.Interval=[TimeSpan]::FromMilliseconds(100)
    $timer.Add_Tick({
        if ($asyncResult.IsCompleted) {
            $timer.Stop(); $elapsedTimer.Stop()
            $global:isRunning = $false
            Set-UIState $false

            # Final stats update from remaining outputs
            if ($null -ne $powershell -and $null -ne $powershell.Streams.Output) {
                foreach ($out in $powershell.Streams.Output) {
                    if ($out.Type -eq "Progress") { $pct=[Math]::Round(($out.Current/$out.Total)*100); $progressMain.Value=$pct; $lblPercentage.Text="$pct%"; $lblFileCount.Text="$($out.Current) / $($out.Total) files"; $lblProgressText.Text="Processing: $($out.File)" }
                    elseif ($out.Type -eq "Log") { Add-Log $out.Msg $out.Sev }
                    elseif ($out.Type -eq "Stat") { $statSuccess.Text=$out.Results.Success; $statFixed.Text=$out.Results.Fixed; $statFailed.Text=$out.Results.Failed }
                    elseif ($out.Type -eq "Done") {
                        $statSuccess.Text=$out.Results.Success; $statFixed.Text=$out.Results.Fixed; $statFailed.Text=$out.Results.Failed
                        $elapsed = if ($global:startTime) { [DateTime]::Now - $global:startTime } else { [TimeSpan]::Zero }
                        $timeStr = if ($elapsed.TotalHours -ge 1) { $elapsed.ToString('hh\:mm\:ss') } else { $elapsed.ToString('mm\:ss') }

                        $lblProgressText.Text = "✅ Complete!"
                        Add-Log "═══════════════════════════════════════" "INFO"
                        Add-Log "COMPLETE — OK: $($out.Results.Success)  |  Fixed: $($out.Results.Fixed)  |  Failed: $($out.Results.Failed)  |  Skipped: $($out.Results.Skipped)" "SUCCESS"
                        Add-Log "Total time: $timeStr" "INFO"
                        Add-Log "═══════════════════════════════════════" "INFO"

                        [System.Windows.MessageBox]::Show(
                            "Scan finished in $timeStr`n`n✅ OK: $($out.Results.Success)`n🛠️ Fixed: $($out.Results.Fixed)`n❌ Failed: $($out.Results.Failed)`n⏭️ Skipped: $($out.Results.Skipped)",
                            "Repair Complete", "OK", "Information")
                    }
                }
                $powershell.Streams.Output.Clear()
            }
            return
        }
        if ($null -ne $powershell -and $null -ne $powershell.Streams.Output) {
            $outputs=$powershell.Streams.Output | ForEach-Object { $_ }; $powershell.Streams.Output.Clear()
            foreach ($out in $outputs) {
                if ($out.Type -eq "Progress") { $pct=[Math]::Round(($out.Current/$out.Total)*100); $progressMain.Value=$pct; $lblPercentage.Text="$pct%"; $lblFileCount.Text="$($out.Current) / $($out.Total) files"; $lblProgressText.Text="Processing: $($out.File)" }
                elseif ($out.Type -eq "Log") { Add-Log $out.Msg $out.Sev }
                elseif ($out.Type -eq "Stat") { $statSuccess.Text=$out.Results.Success; $statFixed.Text=$out.Results.Fixed; $statFailed.Text=$out.Results.Failed }
                elseif ($out.Type -eq "Done") { $statSuccess.Text=$out.Results.Success; $statFixed.Text=$out.Results.Fixed; $statFailed.Text=$out.Results.Failed }
            }
        }
    })
    $timer.Start()
})
$window.ShowDialog() | Out-Null
