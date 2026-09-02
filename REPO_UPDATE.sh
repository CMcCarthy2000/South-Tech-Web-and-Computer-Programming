#!/bin/bash
# ======================================================
# Advanced Git Control Center
# Style: Windows 11 Native Desktop Acrylic
# ======================================================

set +o histexpand

current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
status_summary=$(git status --short 2>/dev/null)

if [ -z "$status_summary" ]; then
    echo "No changes detected in repository."
    read -p "Press Enter to exit..."
    exit 0
fi

formatted_status=$(echo "$status_summary" | awk '{print "• " $0}')

export GIT_CUR_BRANCH="$current_branch"
export GIT_STATUS_FMT="$formatted_status"

gui_output=$(powershell.exe -NoProfile -ExecutionPolicy Bypass -Command '
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

$code = @"
using System;
using System.Runtime.InteropServices;

public class WinEffects {
    [StructLayout(LayoutKind.Sequential)]
    public struct MARGINS {
        public int cxLeftWidth;
        public int cxRightWidth;
        public int cyTopHeight;
        public int cyBottomHeight;
    }

    [DllImport("dwmapi.dll")]
    public static extern int DwmExtendFrameIntoClientArea(IntPtr hwnd, ref MARGINS pMarInset);

    [DllImport("dwmapi.dll")]
    public static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int attrValue, int attrSize);

    public static void EnableAcrylic(IntPtr hwnd) {
        // Enable Dark Mode Frame (DWMWA_USE_IMMERSIVE_DARK_MODE = 20)
        int darkMode = 1;
        DwmSetWindowAttribute(hwnd, 20, ref darkMode, sizeof(int));

        // Extend Glass Frame into the entire Client Area
        MARGINS margins = new MARGINS { cxLeftWidth = -1, cxRightWidth = -1, cyTopHeight = -1, cyBottomHeight = -1 };
        DwmExtendFrameIntoClientArea(hwnd, ref margins);

        // Set System Backdrop to Desktop Acrylic (DWMWA_SYSTEMBACKDROP_TYPE = 38, DWMSBT_TRANSIENTWINDOW = 3)
        int backdrop = 3; 
        DwmSetWindowAttribute(hwnd, 38, ref backdrop, sizeof(int));
    }
}
"@
Add-Type -TypeDefinition $code

$xml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Git Control Center" Height="500" Width="540" 
        WindowStartupLocation="CenterScreen" ResizeMode="NoResize"
        Background="Transparent" Foreground="#FFFFFF" FontFamily="Segoe UI Variable Text, Segoe UI">
    
    <!-- Microsoft Acrylic Recipe: Luminosity + Dark Tint Overlay -->
    <Grid Background="#C0141414">
        <Grid Margin="24">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>

            <StackPanel Grid.Row="0" Margin="0,0,0,18">
                <TextBlock Text="Git Control Center" FontSize="22" FontWeight="SemiBold" Foreground="#FFFFFF"/>
                <TextBlock Text="Configure commit details, branches, and push options" FontSize="12" Foreground="#B0FFFFFF" Margin="0,2,0,0"/>
            </StackPanel>

            <StackPanel Grid.Row="1" Margin="0,0,0,16">
                <TextBlock Text="Commit Message" FontSize="12" FontWeight="Medium" Foreground="#E0E0E0" Margin="0,0,0,6"/>
                <TextBox Name="CommitMsg" Height="36" VerticalContentAlignment="Center" FontSize="13" Padding="8,0,8,0"
                         Background="#25FFFFFF" Foreground="#FFFFFF" BorderBrush="#40FFFFFF" BorderThickness="1"/>
            </StackPanel>

            <StackPanel Grid.Row="2" Margin="0,0,0,16">
                <TextBlock Text="Staged Files Preview" FontSize="12" FontWeight="Medium" Foreground="#E0E0E0" Margin="0,0,0,6"/>
                <Border Background="#20FFFFFF" BorderBrush="#30FFFFFF" BorderThickness="1" CornerRadius="6" Padding="12">
                    <ScrollViewer Height="110" VerticalScrollBarVisibility="Auto">
                        <TextBlock Name="StatusBox" FontSize="11" FontFamily="Cascadia Code, Consolas" Foreground="#76B9ED"/>
                    </ScrollViewer>
                </Border>
            </StackPanel>

            <Grid Grid.Row="3" Margin="0,0,0,24">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="16"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>
                <StackPanel Grid.Column="0">
                    <TextBlock Text="Target Branch" FontSize="12" FontWeight="Medium" Foreground="#E0E0E0" Margin="0,0,0,6"/>
                    <TextBox Name="TargetBranch" Height="34" VerticalContentAlignment="Center" FontSize="12" Padding="8,0,8,0"
                             Background="#25FFFFFF" Foreground="#FFFFFF" BorderBrush="#40FFFFFF" BorderThickness="1"/>
                </StackPanel>
                <StackPanel Grid.Column="2">
                    <TextBlock Text="Sync Strategy" FontSize="12" FontWeight="Medium" Foreground="#E0E0E0" Margin="0,0,0,6"/>
                    <ComboBox Name="SyncStrategy" Height="34" SelectedIndex="0" FontSize="12" VerticalContentAlignment="Center"
                              Background="#25FFFFFF" Foreground="#FFFFFF" BorderBrush="#40FFFFFF" BorderThickness="1">
                        <ComboBoxItem Content="Rebase (Recommended)" Background="#2D2D2D" Foreground="#FFFFFF"/>
                        <ComboBoxItem Content="Merge" Background="#2D2D2D" Foreground="#FFFFFF"/>
                        <ComboBoxItem Content="Force Push (Caution)" Background="#2D2D2D" Foreground="#FFFFFF"/>
                    </ComboBox>
                </StackPanel>
            </Grid>

            <Grid Grid.Row="4">
                <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
                    <Button Name="CancelBtn" Content="Cancel" Width="90" Height="34" Margin="0,0,10,0" 
                            Background="#25FFFFFF" Foreground="#FFFFFF" BorderBrush="#40FFFFFF" BorderThickness="1"/>
                    <Button Name="PushBtn" Content="Commit &amp; Push" Width="130" Height="34" IsDefault="True" 
                            Background="#0067C0" Foreground="#FFFFFF" BorderThickness="0"/>
                </StackPanel>
            </Grid>
        </Grid>
    </Grid>
</Window>
"@

$reader = (New-Object System.Xml.XmlNodeReader ([xml]$xml))
$window = [System.Windows.Markup.XamlReader]::Load($reader)

$window.Add_SourceInitialized({
    $helper = New-Object System.Windows.Interop.WindowInteropHelper($window)
    
    # Make WPF composition target transparent so Windows DWM backdrop shows through
    $hwndSource = [System.Windows.Interop.HwndSource]::FromHwnd($helper.Handle)
    $hwndSource.CompositionTarget.BackgroundColor = [System.Windows.Media.Colors]::Transparent
    
    # Apply native Windows 11 Desktop Acrylic
    [WinEffects]::EnableAcrylic($helper.Handle)
})

$commitMsg = $window.FindName("CommitMsg")
$targetBranch = $window.FindName("TargetBranch")
$statusBox = $window.FindName("StatusBox")
$syncStrategy = $window.FindName("SyncStrategy")
$pushBtn = $window.FindName("PushBtn")
$cancelBtn = $window.FindName("CancelBtn")

$targetBranch.Text = $env:GIT_CUR_BRANCH
$statusBox.Text = $env:GIT_STATUS_FMT

$pushBtn.Add_Click({ 
    if ([string]::IsNullOrWhiteSpace($commitMsg.Text)) {
        [System.Windows.MessageBox]::Show("Please enter a commit message.", "Validation Error", "OK", "Warning")
        return
    }
    $window.DialogResult = $true
    $window.Close() 
})

$cancelBtn.Add_Click({ $window.Close() })
$commitMsg.Focus() | Out-Null

if ($window.ShowDialog() -eq $true) {
    Write-Output "MSG:$($commitMsg.Text)"
    Write-Output "BRANCH:$($targetBranch.Text)"
    Write-Output "STRATEGY:$($syncStrategy.SelectedIndex)"
}
')

commit_message=$(echo "$gui_output" | grep "^MSG:" | sed 's/^MSG://' | tr -d '\r')
target_branch=$(echo "$gui_output" | grep "^BRANCH:" | sed 's/^BRANCH://' | tr -d '\r')
strategy_idx=$(echo "$gui_output" | grep "^STRATEGY:" | sed 's/^STRATEGY://' | tr -d '\r')

if [ -z "$commit_message" ]; then
    echo "Push cancelled."
    exit 1
fi

git add .
git commit -m "$commit_message"

case $strategy_idx in
    0) git pull --rebase origin "$target_branch" ;;
    1) git pull origin "$target_branch" --no-rebase ;;
    2) echo "Force push selected." ;;
esac

if [ "$strategy_idx" -eq 2 ]; then
    git push origin "$target_branch" --force
else
    git push origin "$target_branch"
fi