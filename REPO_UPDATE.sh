#!/bin/bash
# ======================================================
# Advanced Git Control Center
# Style: True Windows Acrylic (Liquid Glass)
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
    internal struct WindowCompositionAttributeData {
        public int Attribute;
        public IntPtr Data;
        public int SizeOfData;
    }

    [StructLayout(LayoutKind.Sequential)]
    internal struct AccentPolicy {
        public int AccentState;
        public int AccentFlags;
        public int GradientColor;
        public int AnimationId;
    }

    [DllImport("user32.dll")]
    internal static extern int SetWindowCompositionAttribute(IntPtr hwnd, ref WindowCompositionAttributeData data);

    [DllImport("dwmapi.dll")]
    public static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int attrValue, int attrSize);

    public static void EnableAcrylic(IntPtr hwnd) {
        // Enable Dark Mode Titlebar
        int darkMode = 1;
        DwmSetWindowAttribute(hwnd, 20, ref darkMode, sizeof(int));

        // Define Accent Policy for Acrylic (State 4 = ACCENT_ENABLE_ACRYLICBLURBEHIND)
        AccentPolicy policy = new AccentPolicy {
            AccentState = 4, 
            // Hex format for GradientColor: AABBGGRR. Here we use a dark translucent tint (approx #AA202020)
            GradientColor = 0xAA202020 
        };

        int structSize = Marshal.SizeOf(policy);
        IntPtr accentPtr = Marshal.AllocHGlobal(structSize);
        Marshal.StructureToPtr(policy, accentPtr, false);

        WindowCompositionAttributeData data = new WindowCompositionAttributeData {
            Attribute = 19, // WCA_ACCENT_POLICY
            SizeOfData = structSize,
            Data = accentPtr
        };

        SetWindowCompositionAttribute(hwnd, ref data);
        Marshal.FreeHGlobal(accentPtr);
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
    
    <!-- Transparent Window Chrome to allow OS Acrylic to show -->
    <WindowChrome.WindowChrome>
        <WindowChrome GlassFrameThickness="-1" CaptionHeight="30"/>
    </WindowChrome.WindowChrome>

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
            <TextBlock Text="Configure commit details, branches, and push options" FontSize="12" Foreground="#D0D0D0" Margin="0,2,0,0"/>
        </StackPanel>

        <StackPanel Grid.Row="1" Margin="0,0,0,16">
            <TextBlock Text="Commit Message" FontSize="12" FontWeight="Medium" Foreground="#E0E0E0" Margin="0,0,0,6"/>
            <TextBox Name="CommitMsg" Height="36" VerticalContentAlignment="Center" FontSize="13" Background="#40101010" Foreground="#FFFFFF" BorderBrush="#50FFFFFF" BorderThickness="1"/>
        </StackPanel>

        <StackPanel Grid.Row="2" Margin="0,0,0,16">
            <TextBlock Text="Staged Files Preview" FontSize="12" FontWeight="Medium" Foreground="#E0E0E0" Margin="0,0,0,6"/>
            <Border Background="#30000000" BorderBrush="#50FFFFFF" BorderThickness="1" CornerRadius="8" Padding="12">
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
                <TextBox Name="TargetBranch" Height="34" VerticalContentAlignment="Center" FontSize="12" Background="#40101010" Foreground="#FFFFFF" BorderBrush="#50FFFFFF" BorderThickness="1"/>
            </StackPanel>
            <StackPanel Grid.Column="2">
                <TextBlock Text="Sync Strategy" FontSize="12" FontWeight="Medium" Foreground="#E0E0E0" Margin="0,0,0,6"/>
                <ComboBox Name="SyncStrategy" Height="34" SelectedIndex="0" FontSize="12" VerticalContentAlignment="Center" Background="#40101010" Foreground="#FFFFFF" BorderBrush="#50FFFFFF" BorderThickness="1">
                    <ComboBoxItem Content="Rebase (Recommended)" Background="#2D2D2D"/>
                    <ComboBoxItem Content="Merge" Background="#2D2D2D"/>
                    <ComboBoxItem Content="Force Push (Caution)" Background="#2D2D2D"/>
                </ComboBox>
            </StackPanel>
        </Grid>

        <Grid Grid.Row="4">
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
                <Button Name="CancelBtn" Content="Cancel" Width="90" Height="34" Margin="0,0,10,0" Background="#40101010" Foreground="#FFFFFF" BorderBrush="#50FFFFFF" BorderThickness="1"/>
                <Button Name="PushBtn" Content="Commit &amp; Push" Width="130" Height="34" IsDefault="True" Background="#900067C0" Foreground="#FFFFFF" BorderBrush="#50FFFFFF" BorderThickness="1"/>
            </StackPanel>
        </Grid>
    </Grid>
</Window>
"@

$reader = (New-Object System.Xml.XmlNodeReader ([xml]$xml))
$window = [System.Windows.Markup.XamlReader]::Load($reader)

$window.Add_SourceInitialized({
    $helper = New-Object System.Windows.Interop.WindowInteropHelper($window)
    
    # Fix the WPF Black Background
    $hwndSource = [System.Windows.Interop.HwndSource]::FromHwnd($helper.Handle)
    $hwndSource.CompositionTarget.BackgroundColor = [System.Windows.Media.Colors]::Transparent
    
    # Apply True Acrylic
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