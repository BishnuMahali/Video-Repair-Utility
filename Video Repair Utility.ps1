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
    @{ WindowBg="#1B1F23"; CardBg="#24292E"; TextMain="#E6EDF3"; TextSub="#8C959F"; Border="#30363D"; InputBg="#0D1117"; Primary="#3498DB"; Accent="#2980B9"; Shadow="#000000"; ProgressBg="#30363D"; Success="#27AE60"; Error="#E74C3C"; Hover="#4AA3DF" }
} else {
    @{ WindowBg="#F4F4F9"; CardBg="#FFFFFF"; TextMain="#2C3E50"; TextSub="#7F8C8D"; Border="#DCDDE1"; InputBg="#FDFDFD"; Primary="#3498DB"; Accent="#2980B9"; Shadow="#D0D0D0"; ProgressBg="#ECF0F1"; Success="#27AE60"; Error="#E74C3C"; Hover="#1B78B7" }
}

# ==========================================
# XAML UI DEFINITION
# ==========================================
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Ultimate Video Repair Utility" Height="850" Width="950" Background="$($Theme.WindowBg)" WindowStartupLocation="CenterScreen">
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
        <Style x:Key="CardStyle" TargetType="Border"><Setter Property="Background" Value="$($Theme.CardBg)"/><Setter Property="CornerRadius" Value="10"/><Setter Property="Padding" Value="20"/><Setter Property="Margin" Value="0,0,0,20"/><Setter Property="BorderBrush" Value="$($Theme.Border)"/><Setter Property="BorderThickness" Value="1"/><Setter Property="Effect"><Setter.Value><DropShadowEffect BlurRadius="15" Color="$($Theme.Shadow)" ShadowDepth="2" Opacity="0.4"/></Setter.Value></Setter></Style>
        <Style x:Key="PrimaryButtonStyle" TargetType="Button"><Setter Property="Background" Value="$($Theme.Primary)"/><Setter Property="Foreground" Value="White"/><Setter Property="FontWeight" Value="Bold"/><Setter Property="Padding" Value="15,10"/><Setter Property="BorderThickness" Value="0"/><Setter Property="Cursor" Value="Hand"/><Setter Property="Height" Value="45"/><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border Name="Border" Background="{TemplateBinding Background}" CornerRadius="5"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Border" Property="Background" Value="$($Theme.Hover)"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>
        <Style x:Key="SecondaryButtonStyle" TargetType="Button"><Setter Property="Background" Value="$($Theme.InputBg)"/><Setter Property="Foreground" Value="$($Theme.TextMain)"/><Setter Property="BorderBrush" Value="$($Theme.Border)"/><Setter Property="BorderThickness" Value="1"/><Setter Property="Cursor" Value="Hand"/><Setter Property="Height" Value="35"/><Setter Property="Template"><Setter.Value><ControlTemplate TargetType="Button"><Border Name="Border" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="4"><ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/></Border><ControlTemplate.Triggers><Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Border" Property="Background" Value="$($Theme.CardBg)"/></Trigger></ControlTemplate.Triggers></ControlTemplate></Setter.Value></Setter></Style>
    </Window.Resources>

    <Grid Margin="30">
        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
        <StackPanel Grid.Row="0" Margin="0,0,0,25"><TextBlock Text="VIDEO REPAIR PRO" FontWeight="Bold" FontSize="24"/><TextBlock Text="Automatic scan, verification, and restoration of corrupted media" Foreground="$($Theme.TextSub)" FontSize="14"/></StackPanel>
        <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto">
            <StackPanel>
                <Border Style="{StaticResource CardStyle}"><StackPanel><TextBlock Text="1. SCANNING DIRECTORY" FontWeight="SemiBold" Margin="0,0,0,10" Foreground="$($Theme.TextSub)"/><Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions><TextBox x:Name="txtPath" Grid.Column="0" Height="35" IsReadOnly="True"/><Button x:Name="btnBrowse" Grid.Column="1" Content="Browse" Width="100" Margin="10,0,0,0" Height="35" Style="{StaticResource SecondaryButtonStyle}"/></Grid><StackPanel Orientation="Horizontal" Margin="0,15,0,0"><CheckBox x:Name="chkRecurse" Content="Include Subfolders"/><CheckBox x:Name="chkDelete" Content="Delete broken files" Margin="20,0,0,0" Foreground="$($Theme.Error)"/></StackPanel></StackPanel></Border>
                <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                    <Border Style="{StaticResource CardStyle}" Grid.Column="0" Margin="0,0,10,20"><StackPanel><TextBlock Text="2. STRATEGY" FontWeight="SemiBold" Margin="0,0,0,15" Foreground="$($Theme.TextSub)"/><ComboBox x:Name="comboCodec" Height="30" Margin="0,0,0,15"><ComboBoxItem Content="H.264" IsSelected="True"/><ComboBoxItem Content="HEVC"/><ComboBoxItem Content="AV1"/></ComboBox><ComboBox x:Name="comboGpu" Height="30"/></StackPanel></Border>
                    <Border Style="{StaticResource CardStyle}" Grid.Column="1" Margin="10,0,0,20"><StackPanel><TextBlock Text="3. INTENSITY" FontWeight="SemiBold" Margin="0,0,0,15" Foreground="$($Theme.TextSub)"/><RadioButton x:Name="rbStandard" Content="Standard Fix" IsChecked="True" Margin="0,0,0,10"/><RadioButton x:Name="rbAggressive" Content="Aggressive Fix"/></StackPanel></Border>
                </Grid>
                <Border Style="{StaticResource CardStyle}"><StackPanel><TextBlock Text="4. SESSION OPTIONS" FontWeight="SemiBold" Margin="0,0,0,10" Foreground="$($Theme.TextSub)"/><CheckBox x:Name="chkResume" Content="Enable Resume Functionality" IsChecked="True" Margin="0,0,0,8"/><CheckBox x:Name="chkCache" Content="Enable Cache for Faster Processing" IsChecked="True" Margin="0,0,0,8"/><CheckBox x:Name="chkLog" Content="Enable Log" IsChecked="True"/></StackPanel></Border>
                <Border Style="{StaticResource CardStyle}">
                    <StackPanel><Grid Margin="0,0,0,10"><TextBlock x:Name="lblProgressText" Text="Ready"/><TextBlock x:Name="lblPercentage" HorizontalAlignment="Right" Text="0%" FontWeight="Bold" Foreground="$($Theme.Primary)"/></Grid><ProgressBar x:Name="progressMain" Height="10" Background="$($Theme.ProgressBg)" Foreground="$($Theme.Primary)" BorderThickness="0"/>
                    <UniformGrid Columns="3" Margin="0,15,0,0">
                        <StackPanel><TextBlock Text="SUCCESS" FontSize="10" Foreground="$($Theme.Success)" FontWeight="Bold" HorizontalAlignment="Center"/><TextBlock x:Name="statSuccess" Text="0" FontSize="20" FontWeight="Bold" HorizontalAlignment="Center"/></StackPanel>
                        <StackPanel><TextBlock Text="FIXED" FontSize="10" Foreground="$($Theme.Accent)" FontWeight="Bold" HorizontalAlignment="Center"/><TextBlock x:Name="statFixed" Text="0" FontSize="20" FontWeight="Bold" HorizontalAlignment="Center"/></StackPanel>
                        <StackPanel><TextBlock Text="FAILED" FontSize="10" Foreground="$($Theme.Error)" FontWeight="Bold" HorizontalAlignment="Center"/><TextBlock x:Name="statFailed" Text="0" FontSize="20" FontWeight="Bold" HorizontalAlignment="Center"/></StackPanel>
                    </UniformGrid></StackPanel>
                </Border>
                <Border Background="$($Theme.InputBg)" CornerRadius="5" Padding="10" Height="150" BorderBrush="$($Theme.Border)" BorderThickness="1"><TextBox x:Name="txtLogs" Background="Transparent" Foreground="$($Theme.TextMain)" BorderThickness="0" IsReadOnly="True" VerticalScrollBarVisibility="Auto" FontFamily="Consolas" FontSize="11"/></Border>
            </StackPanel>
        </ScrollViewer>
        <Grid Grid.Row="2" Margin="0,10,0,0"><StackPanel Orientation="Horizontal"><TextBlock Text="FFmpeg: "/><TextBlock x:Name="lblFfmpegStatus" Text="..." FontWeight="Bold"/></StackPanel><Button x:Name="btnStart" Content="START REPAIR" Style="{StaticResource PrimaryButtonStyle}" HorizontalAlignment="Right" Width="180"/></Grid>
    </Grid>
</Window>"
@

$reader = New-Object System.Xml.XmlNodeReader $xaml; $window = [Windows.Markup.XamlReader]::Load($reader)
$txtPath=$window.FindName("txtPath"); $btnBrowse=$window.FindName("btnBrowse"); $chkRecurse=$window.FindName("chkRecurse"); $chkDelete=$window.FindName("chkDelete"); $comboCodec=$window.FindName("comboCodec"); $comboGpu=$window.FindName("comboGpu"); $rbStandard=$window.FindName("rbStandard"); $rbAggressive=$window.FindName("rbAggressive"); $chkResume=$window.FindName("chkResume"); $chkCache=$window.FindName("chkCache"); $chkLog=$window.FindName("chkLog"); $lblProgressText=$window.FindName("lblProgressText"); $lblPercentage=$window.FindName("lblPercentage"); $progressMain=$window.FindName("progressMain"); $statSuccess=$window.FindName("statSuccess"); $statFixed=$window.FindName("statFixed"); $statFailed=$window.FindName("statFailed"); $txtLogs=$window.FindName("txtLogs"); $lblFfmpegStatus=$window.FindName("lblFfmpegStatus"); $btnStart=$window.FindName("btnStart")

$global:logEnabled=$false; $global:logFilePath=""
$knownVideoExtensions = @(".mp4",".mkv",".avi",".mov",".flv",".wmv",".asf",".mpeg",".mpg",".webm",".vob",".mp4v",".m4v",".3gp",".3g2",".ts",".mts",".m2ts",".divx",".xvid",".f4v",".rmvb")
$brokenFolderName = "Broken Files"
$EncodersDict = @{ "H.264" = @{CPU="libx264"; NVIDIA="h264_nvenc"; AMD="h264_amf"; Intel="h264_qsv"}; "HEVC" = @{CPU="libx265"; NVIDIA="hevc_nvenc"; AMD="hevc_amf"; Intel="hevc_qsv"}; "AV1" = @{CPU="libsvtav1"; NVIDIA="av1_nvenc"; AMD="av1_amf"; Intel="av1_qsv"} }

function Add-Log { param([string]$msg, [string]$type="INFO") $window.Dispatcher.Invoke({ $ts = "[$(Get-Date -Format 'HH:mm:ss')] [$type] $msg"; $txtLogs.AppendText("$ts`r`n"); $txtLogs.ScrollToEnd(); if ($global:logEnabled -and $global:logFilePath) { try { Add-Content -Path $global:logFilePath -Value $ts -ErrorAction SilentlyContinue } catch {} } }) }
function Check-FFmpeg { if (Get-Command ffmpeg -ErrorAction SilentlyContinue) { $lblFfmpegStatus.Text = "ACTIVE"; $lblFfmpegStatus.Foreground = [System.Windows.Media.Brushes]::Green; return $true }; $lblFfmpegStatus.Text = "MISSING"; $lblFfmpegStatus.Foreground = [System.Windows.Media.Brushes]::Red; return $false }
function Update-GpuList {
    $codecName=$comboCodec.Text.Split(" ")[0]; $ffmpegEncoders=(ffmpeg -encoders 2>&1 | Out-String); $comboGpu.Items.Clear()
    foreach ($vendor in @("CPU", "NVIDIA", "AMD", "Intel")) {
        $encoder=$EncodersDict[$codecName][$vendor]; $color="#6E7781"; $status="Not Supported"
        if ($vendor -eq "CPU") { $supported=$true; $color="#2DA44E"; $status="Confirmed" }
        elseif ($ffmpegEncoders -match "\b$encoder\b") {
            $dummy=@("-v","error","-f","lavfi","-i","color=black:s=1280x720:r=24","-pix_fmt","yuv420p","-vframes","1","-c:v",$encoder,"-f","null","-")
            $null = & ffmpeg @dummy 2>&1
            if ($LASTEXITCODE -eq 0) { $supported=$true; $color="#2DA44E"; $status="Confirmed" } else { $supported=$false; $color="#D29922"; $status="Init Failed" }
        }
        $item=New-Object System.Windows.Controls.ComboBoxItem; $stack=New-Object System.Windows.Controls.StackPanel; $stack.Orientation="Horizontal"
        $circle=New-Object System.Windows.Controls.Border; $circle.Width=10; $circle.Height=10; $circle.CornerRadius=5; $circle.Margin="0,0,10,0"; $circle.Background=[System.Windows.Media.BrushConverter]::new().ConvertFromString($color)
        $text=New-Object System.Windows.Controls.TextBlock; $text.Text=$vendor; $text.Foreground=[System.Windows.Media.BrushConverter]::new().ConvertFromString($Theme.TextMain)
        $stack.Children.Add($circle); $stack.Children.Add($text); $item.Content=$stack; $item.Tag=$encoder; $item.ToolTip=$status; $comboGpu.Items.Add($item)
    }
    $comboGpu.SelectedIndex = 0
}

$txtPath.Text=$PWD.Path; Check-FFmpeg; Update-GpuList
$btnBrowse.Add_Click({ Add-Type -AssemblyName System.Windows.Forms; $dialog=New-Object System.Windows.Forms.FolderBrowserDialog; $dialog.SelectedPath=$txtPath.Text; if ($dialog.ShowDialog() -eq "OK") { $txtPath.Text=$dialog.SelectedPath } })
$comboCodec.Add_SelectionChanged({ Update-GpuList })
$chkResume.Add_Click({ if ($chkResume.IsChecked) { $chkCache.IsChecked=$true } }); $chkCache.Add_Click({ if (-not $chkCache.IsChecked) { $chkResume.IsChecked=$false } })

$btnStart.Add_Click({
    if (-not (Check-FFmpeg)) { return }; $btnStart.IsEnabled=$false; $btnBrowse.IsEnabled=$false; $global:logEnabled=$chkLog.IsChecked
    $workDir=Join-Path $txtPath.Text ".Video Repair Utility"; if ($chkCache.IsChecked -or $chkLog.IsChecked) { if (-not (Test-Path $workDir)) { $hd=New-Item -ItemType Directory -Path $workDir -Force; $hd.Attributes="Directory","Hidden" } }
    $cacheFile=Join-Path $workDir "Cache.json"; $global:logFilePath=Join-Path $workDir "Log.txt"
    $cache=@{}; if ($chkResume.IsChecked -and (Test-Path $cacheFile)) { try { $json=Get-Content $cacheFile -Raw | ConvertFrom-Json; foreach($e in $json){ if($e.Path){$cache[$e.Path.ToLowerInvariant()]=$e} } } catch {} }
    $config=@{ Dir=$txtPath.Text; Recurse=$chkRecurse.IsChecked; Delete=$chkDelete.IsChecked; Force=$rbAggressive.IsChecked; Encoder=$comboGpu.SelectedItem.Tag; Exts=$knownVideoExtensions; BrokenName=$brokenFolderName; CacheEnabled=$chkCache.IsChecked; CacheFile=$cacheFile; Cache=$cache; ResumeEnabled=$chkResume.IsChecked }
    $job={ param($config)
        $results=@{ Success=0; Fixed=0; Failed=0 }
        $files=Get-ChildItem -Path $config.Dir -File -Recurse:$config.Recurse | Where-Object { $config.Exts -contains $_.Extension.ToLower() }
        $total=$files.Count; $current=0
        $brokenPath=Join-Path $config.Dir $config.BrokenName; if (-not $config.Delete -and -not (Test-Path $brokenPath)) { New-Item -ItemType Directory -Path $brokenPath | Out-Null }
        foreach ($file in $files) {
            $current++; $key=$file.FullName.ToLowerInvariant(); $sig="$($file.Length)|$($file.LastWriteTimeUtc.Ticks)"
            Write-Output @{ Type="Progress"; Current=$current; Total=$total; File=$file.Name }
            if ($config.ResumeEnabled -and $config.Cache.ContainsKey($key)) { if ($config.Cache[$key].Signature -eq $sig) { Write-Output @{ Type="Log"; Msg="Cached Skip: $($file.Name)"; Sev="INFO" }; continue } }
            $isBroken = $false; $codecMissing = $false
            if (@(".avi", ".wmv", ".flv", ".vob", ".ts") -contains $file.Extension.ToLower()) { $codecName = & ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$($file.FullName)" 2>&1; if ($codecName -match "rawvideo") { $codecMissing = $true; $isBroken = $true } }
            if (-not $isBroken) { $demux=& ffmpeg -v error -i "$($file.FullName)" -c copy -f null - 2>&1; if (-not [string]::IsNullOrWhiteSpace($demux)) { $isBroken = $true } }
            if (-not $isBroken) { $results.Success++; Write-Output @{ Type="Log"; Msg="OK: $($file.Name)"; Sev="SUCCESS" }; continue }
            if ($codecMissing) {
                Write-Output @{ Type="Log"; Msg="Codec missing detected. Attempting recovery: $($file.Name)"; Sev="WARNING" }
                $tmp="$($file.FullName).tmp.mp4"; & ffmpeg -y -loglevel error -c:v hevc -i "$($file.FullName)" -c copy -movflags +faststart "$tmp" 2>$null
                if ($LASTEXITCODE -ne 0) { & ffmpeg -y -loglevel error -c:v av1 -i "$($file.FullName)" -c copy -movflags +faststart "$tmp" 2>$null }
                if ($LASTEXITCODE -eq 0 -and (Test-Path $tmp)) {
                    $newFile = [System.IO.Path]::ChangeExtension($file.FullName, ".mp4")
                    if ((Test-Path $newFile) -and ($newFile -ne $file.FullName)) { Remove-Item $newFile -Force }
                    Move-Item $tmp $newFile -Force
                    if ($newFile -ne $file.FullName) { if ($config.Delete) { Remove-Item $file.FullName -Force } else { Move-Item $file.FullName $brokenPath -Force } }
                    $results.Fixed++; Write-Output @{ Type="Log"; Msg="CODEC RECOVERED: $($file.Name)"; Sev="WARNING" }
                    if ($config.CacheEnabled) { $config.Cache[$key]=@{Path=$file.FullName; Signature=$sig; Status="Processed"}; $config.Cache.Values | ConvertTo-Json -Depth 4 | Set-Content $config.CacheFile }
                    continue
                }
                if (Test-Path $tmp) { Remove-Item $tmp -Force }
            }
            $tmp="$($file.FullName).tmp.mp4"; if ($config.Force) { & ffmpeg -y -err_detect ignore_err -fflags +genpts+discardcorrupt -async 1 -i "$($file.FullName)" -c:v $config.Encoder -c:a aac "$tmp" 2>$null } else { & ffmpeg -y -i "$($file.FullName)" -c copy "$tmp" 2>$null }
            if ($LASTEXITCODE -eq 0 -and (Test-Path $tmp)) { Move-Item $tmp $file.FullName -Force; $results.Fixed++; Write-Output @{ Type="Log"; Msg="FIXED: $($file.Name)"; Sev="WARNING" } }
            else { if (Test-Path $tmp) { Remove-Item $tmp -Force }; $results.Failed++; Write-Output @{ Type="Log"; Msg="FAILED: $($file.Name)"; Sev="ERROR" }; if ($config.Delete) { Remove-Item $file.FullName -Force } else { Move-Item $file.FullName $brokenPath -Force } }
            if ($config.CacheEnabled) { $config.Cache[$key]=@{Path=$file.FullName; Signature=$sig; Status="Processed"}; $config.Cache.Values | ConvertTo-Json -Depth 4 | Set-Content $config.CacheFile }
        }
        Write-Output @{ Type="Done"; Results=$results }
    }
    $powershell=[PowerShell]::Create().AddScript($job).AddArgument($config); $asyncResult=$powershell.BeginInvoke()
    $timer=New-Object System.Windows.Threading.DispatcherTimer; $timer.Interval=[TimeSpan]::FromMilliseconds(100)
    $timer.Add_Tick({
        if ($asyncResult.IsCompleted) { $timer.Stop(); $btnStart.IsEnabled=$true; $btnBrowse.IsEnabled=$true; return }
        if ($null -ne $powershell -and $null -ne $powershell.Streams.Output) {
            $outputs=$powershell.Streams.Output | Select-Object -Last 10; $powershell.Streams.Output.Clear()
            foreach ($out in $outputs) {
                if ($out.Type -eq "Progress") { $pct=[Math]::Round(($out.Current/$out.Total)*100); $progressMain.Value=$pct; $lblPercentage.Text="$pct%"; $lblProgressText.Text="Processing: $($out.File)" }
                elseif ($out.Type -eq "Log") { Add-Log $out.Msg $out.Sev }
                elseif ($out.Type -eq "Done") { $statSuccess.Text=$out.Results.Success; $statFixed.Text=$out.Results.Fixed; $statFailed.Text=$out.Results.Failed }
            }
        }
    })
    $timer.Start()
})
$window.ShowDialog() | Out-Null
