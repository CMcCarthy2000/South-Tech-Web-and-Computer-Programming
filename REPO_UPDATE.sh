#!/bin/bash
# ======================================================
# Advanced Git Control Center (Commit & Push)
# Style: Windows 10 & 11 Modern Dark Theme
# ======================================================

# Disable Bash history expansion to prevent '!-: event not found' errors
set +o histexpand

# 1. Gather current Git context
current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
status_summary=$(git status --short 2>/dev/null)

if [ -z "$status_summary" ]; then
    echo "No changes detected in repository."
    read -p "Press Enter to exit..."
    exit 0
fi

# Format git status for display
formatted_status=$(echo "$status_summary" | awk '{print "• " $0}')

# Pass variables to PowerShell safely using environment variables
export GIT_CUR_BRANCH="$current_branch"
export GIT_STATUS_FMT="$formatted_status"

# 2. Open Modern Control Panel (Wrapped in strict single quotes)
gui_output=$(powershell.exe -NoProfile -ExecutionPolicy Bypass -Command '
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

$code = @"
using System;
using System.Runtime.InteropServices;

public class WinEffects {
    [DllImport("dwmapi.dll")]
    public static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int attrValue, int attrSize);

    public static void ApplyTheme(IntPtr hwnd) {
        try {
            int darkMode = 1;
            DwmSetWindowAttribute(hwnd, 20, ref darkMode, sizeof(int));
            DwmSetWindowAttribute(hwnd, 19, ref darkMode, sizeof(int));

            int backdrop = 3; 
            DwmSetWindowAttribute(hwnd, 38, ref backdrop, sizeof(int));
        } catch { }
    }
}
"@
Add-Type -TypeDefinition $code

$xml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Git Control Center" Height="500" Width="540" 
        WindowStartupLocation="CenterScreen" ResizeMode="NoResize"
        Background="#1E1E1E" Foreground="#FFFFFF" FontFamily="Segoe UI Variable Text, Segoe UI">
    <Window.Resources>
        <Style TargetType="TextBox">
            <Setter Property="Background" Value="#2D2D2D"/>
            <Setter Property="Foreground" Value="#FFFFFF"/>
            <Setter Property="BorderBrush" Value="#404040"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="10,6"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="TextBox">
                        <Border x:Name="border" Background="{TemplateBinding Background}" 
                                BorderBrush="{TemplateBinding BorderBrush}" 
                                BorderThickness="{TemplateBinding BorderThickness}" 
                                CornerRadius="6">
                            <ScrollViewer x:Name="PART_ContentHost" Focusable="false" HorizontalScrollBarVisibility="Hidden" VerticalScrollBarVisibility="Hidden"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style TargetType="ComboBoxItem">
            <Setter Property="Background" Value="#2D2D2D"/>
            <Setter Property="Foreground" Value="#FFFFFF"/>
            <Setter Property="Padding" Value="8,6"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ComboBoxItem">
                        <Border x:Name="Bd" Background="{TemplateBinding Background}" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Left" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Bd" Property="Background" Value="#0067C0"/>
                            </Trigger>
                            <Trigger Property="IsSelected" Value="True">
                                <Setter TargetName="Bd" Property="Background" Value="#383838"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <Style TargetType="ComboBox">
            <Setter Property="Foreground" Value="#FFFFFF"/>
            <Setter Property="Background" Value="#2D2D2D"/>
            <Setter Property="BorderBrush" Value="#404040"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ComboBox">
                        <Grid Name="MainGrid">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="30"/>
                            </Grid.ColumnDefinitions>
                            <Border Grid.ColumnSpan="2" Background="#2D2D2D" BorderBrush="#404040" BorderThickness="1" CornerRadius="6"/>
                            <ContentPresenter Margin="10,0,0,0" VerticalAlignment="Center" HorizontalAlignment="Left" Content="{TemplateBinding SelectionBoxItem}" ContentTemplate="{TemplateBinding SelectionBoxItemTemplate}" ContentTemplateSelector="{TemplateBinding ItemTemplateSelector}" IsHitTestVisible="False"/>
                            <ToggleButton Grid.Column="1" Background="Transparent" BorderBrush="Transparent" IsChecked="{Binding Path=IsDropDownOpen, Mode=TwoWay, RelativeSource={RelativeSource TemplatedParent}}">
                                <ToggleButton.Template>
                                    <ControlTemplate TargetType="ToggleButton">
                                        <Border Background="Transparent">
                                            <Path Data="M 0 0 L 4 4 L 8 0 Z" Fill="#FFFFFF" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                        </Border>
                                    </ControlTemplate>
                                </ToggleButton.Template>
                            </ToggleButton>
                            <Popup Name="PART_Popup" IsOpen="{TemplateBinding IsDropDownOpen}" Placement="Bottom" PopupAnimation="Slide" AllowDrop="True">
                                <Border Name="DropDownBorder" Background="#2D2D2D" BorderBrush="#404040" BorderThickness="1" CornerRadius="6" Margin="0,2,0,0" MinWidth="{TemplateBinding ActualWidth}">
                                    <ScrollViewer x:Name="DropDownScrollViewer">
                                        <ItemsPresenter x:Name="ItemsPresenter" KeyboardNavigation.DirectionalNavigation="Contained"/>
                                    </ScrollViewer>
                                </Border>
                            </Popup>
                        </Grid>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

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
            <TextBlock Text="Configure commit details, branches, and push options" FontSize="12" Foreground="#A0A0A0" Margin="0,2,0,0"/>
        </StackPanel>

        <StackPanel Grid.Row="1" Margin="0,0,0,16">
            <TextBlock Text="Commit Message" FontSize="12" FontWeight="Medium" Foreground="#D0D0D0" Margin="0,0,0,6"/>
            <TextBox Name="CommitMsg" Height="36" VerticalContentAlignment="Center" FontSize="13"/>
        </StackPanel>

        <StackPanel Grid.Row="2" Margin="0,0,0,16">
            <TextBlock Text="Staged Files Preview" FontSize="12" FontWeight="Medium" Foreground="#D0D0D0" Margin="0,0,0,6"/>
            <Border Background="#202020" BorderBrush="#383838" BorderThickness="1" CornerRadius="8" Padding="12">
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
                <TextBlock Text="Target Branch" FontSize="12" FontWeight="Medium" Foreground="#D0D0D0" Margin="0,0,0,6"/>
                <TextBox Name="TargetBranch" Height="34" VerticalContentAlignment="Center" FontSize="12"/>
            </StackPanel>

            <StackPanel Grid.Column="2">
                <TextBlock Text="Sync Strategy" FontSize="12" FontWeight="Medium" Foreground="#D0D0D0" Margin="0,0,0,6"/>
                <ComboBox Name="SyncStrategy" Height="34" SelectedIndex="0" FontSize="12" VerticalContentAlignment="Center">
                    <ComboBoxItem Content="Rebase (Recommended)"/>
                    <ComboBoxItem Content="Merge"/>
                    <ComboBoxItem Content="Force Push (Caution)"/>
                </ComboBox>
            </StackPanel>
        </Grid>

        <Grid Grid.Row="4">
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
                <Button Name="CancelBtn" Content="Cancel" Width="90" Height="34" Margin="0,0,10,0">
                    <Button.Template>
                        <ControlTemplate TargetType="Button">
                            <Border Background="#2D2D2D" BorderBrush="#404040" BorderThickness="1" CornerRadius="6">
                                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                            </Border>
                        </ControlTemplate>
                    </Button.Template>
                </Button>
                <Button Name="PushBtn" Content="Commit &amp; Push" Width="130" Height="34" IsDefault="True" Foreground="#FFFFFF" FontWeight="SemiBold">
                    <Button.Template>
                        <ControlTemplate TargetType="Button">
                            <Border Background="#0067C0" CornerRadius="6">
                                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                            </Border>
                        </ControlTemplate>
                    </Button.Template>
                </Button>
            </StackPanel>
        </Grid>
    </Grid>
</Window>
"@

$reader = (New-Object System.Xml.XmlNodeReader ([xml]$xml))
$window = [System.Windows.Markup.XamlReader]::Load($reader)

$window.Add_Loaded({
    $helper = New-Object System.Windows.Interop.WindowInteropHelper($window)
    [WinEffects]::ApplyTheme($helper.Handle)
})

$commitMsg = $window.FindName("CommitMsg")
$targetBranch = $window.FindName("TargetBranch")
$statusBox = $window.FindName("StatusBox")
$syncStrategy = $window.FindName("SyncStrategy")
$pushBtn = $window.FindName("PushBtn")
$cancelBtn = $window.FindName("CancelBtn")

# Inject Data Safely via Environment Variables
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

# 3. Parse PowerShell Output
commit_message=$(echo "$gui_output" | grep "^MSG:" | sed 's/^MSG://' | tr -d '\r')
target_branch=$(echo "$gui_output" | grep "^BRANCH:" | sed 's/^BRANCH://' | tr -d '\r')
strategy_idx=$(echo "$gui_output" | grep "^STRATEGY:" | sed 's/^STRATEGY://' | tr -d '\r')

if [ -z "$commit_message" ]; then
    echo "Push cancelled: Operation aborted."
    read -p "Press Enter to exit..."
    exit 1
fi

# 4. Execute Git Workflow
echo ""
echo "------------------------------------------------------"
echo "Processing Git Operations..."
echo "------------------------------------------------------"

# Stage all files
git add .

# Commit
git commit -m "$commit_message"

# Sync with Remote according to strategy chosen
echo "Syncing with remote branch '$target_branch'..."
case $strategy_idx in
    0)
        git pull --rebase origin "$target_branch"
        ;;
    1)
        git pull origin "$target_branch" --no-rebase
        ;;
    2)
        echo "Caution: Force push selected. Skipping pull."
        ;;
esac

# Push
if [ "$strategy_idx" -eq 2 ]; then
    git push origin "$target_branch" --force
else
    git push origin "$target_branch"
fi

# 5. Keep terminal open
echo "------------------------------------------------------"
echo "Process complete!"
read -p "Press Enter to close terminal..."