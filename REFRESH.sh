#!/bin/bash
# ======================================================
# Advanced Git Pull & Refresh Center
# Style: Windows 10 & 11 Modern Dark Theme
# Created: 8/31/2026 | Updated: 9/01/2026
# ======================================================

# 1. Gather current Git context
current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
status_summary=$(git status --short 2>/dev/null)

if [ -z "$status_summary" ]; then
    formatted_status="• Working tree clean (No uncommitted changes)"
else
    formatted_status=$(echo "$status_summary" | sed 's/"/\\"/g' | awk '{print "• " $0}')
fi

# 2. Open Modern Control Panel for Pull Options
gui_output=$(powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

\$code = @'
using System;
using System.Runtime.InteropServices;

public class WinEffects {
    [DllImport(\"dwmapi.dll\")]
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
'@
Add-Type -TypeDefinition \$code

\$xml = @'
<Window xmlns=\"http://schemas.microsoft.com/winfx/2006/xaml/presentation\"
        xmlns:x=\"http://schemas.microsoft.com/winfx/2006/xaml\"
        Title=\"Git Sync &amp; Refresh\" Height=\"440\" Width=\"540\" 
        WindowStartupLocation=\"CenterScreen\" ResizeMode=\"NoResize\"
        Background=\"#1E1E1E\" Foreground=\"#FFFFFF\" FontFamily=\"Segoe UI Variable Text, Segoe UI\">
    <Window.Resources>
        <!-- Custom ComboBox Item Style -->
        <Style TargetType=\"ComboBoxItem\">
            <Setter Property=\"Background\" Value=\"#2D2D2D\"/>
            <Setter Property=\"Foreground\" Value=\"#FFFFFF\"/>
            <Setter Property=\"Padding\" Value=\"8,6\"/>
            <Setter Property=\"Template\">
                <Setter.Value>
                    <ControlTemplate TargetType=\"ComboBoxItem\">
                        <Border x:Name=\"Bd\" Background=\"{TemplateBinding Background}\" Padding=\"{TemplateBinding Padding}\">
                            <ContentPresenter HorizontalAlignment=\"Left\" VerticalAlignment=\"Center\"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property=\"IsMouseOver\" Value=\"True\">
                                <Setter TargetName=\"Bd\" Property=\"Background\" Value=\"#0067C0\"/>
                            </Trigger>
                            <Trigger Property=\"IsSelected\" Value=\"True\">
                                <Setter TargetName=\"Bd\" Property=\"Background\" Value=\"#383838\"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Custom ComboBox Style -->
        <Style TargetType=\"ComboBox\">
            <Setter Property=\"Foreground\" Value=\"#FFFFFF\"/>
            <Setter Property=\"Background\" Value=\"#2D2D2D\"/>
            <Setter Property=\"BorderBrush\" Value=\"#404040\"/>
            <Setter Property=\"BorderThickness\" Value=\"1\"/>
            <Setter Property=\"Template\">
                <Setter.Value>
                    <ControlTemplate TargetType=\"ComboBox\">
                        <Grid Name=\"MainGrid\">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width=\"*\"/>
                                <ColumnDefinition Width=\"30\"/>
                            </Grid.ColumnDefinitions>
                            <Border Grid.ColumnSpan=\"2\" Background=\"#2D2D2D\" BorderBrush=\"#404040\" BorderThickness=\"1\" CornerRadius=\"6\"/>
                            <ContentPresenter Margin=\"10,0,0,0\" VerticalAlignment=\"Center\" HorizontalAlignment=\"Left\" Content=\"{TemplateBinding SelectionBoxItem}\" ContentTemplate=\"{TemplateBinding SelectionBoxItemTemplate}\" ContentTemplateSelector=\"{TemplateBinding ItemTemplateSelector}\" IsHitTestVisible=\"False\"/>
                            <ToggleButton Grid.Column=\"1\" Background=\"Transparent\" BorderBrush=\"Transparent\" IsChecked=\"{Binding Path=IsDropDownOpen, Mode=TwoWay, RelativeSource={RelativeSource TemplatedParent}}\">
                                <ToggleButton.Template>
                                    <ControlTemplate TargetType=\"ToggleButton\">
                                        <Border Background=\"Transparent\">
                                            <Path Data=\"M 0 0 L 4 4 L 8 0 Z\" Fill=\"#FFFFFF\" HorizontalAlignment=\"Center\" VerticalAlignment=\"Center\"/>
                                        </Border>
                                    </ControlTemplate>
                                </ToggleButton.Template>
                            </ToggleButton>
                            <Popup Name=\"PART_Popup\" IsOpen=\"{TemplateBinding IsDropDownOpen}\" Placement=\"Bottom\" PopupAnimation=\"Slide\" AllowDrop=\"True\">
                                <Border Name=\"DropDownBorder\" Background=\"#2D2D2D\" BorderBrush=\"#404040\" BorderThickness=\"1\" CornerRadius=\"6\" Margin=\"0,2,0,0\" MinWidth=\"{TemplateBinding ActualWidth}\">
                                    <ScrollViewer x:Name=\"DropDownScrollViewer\">
                                        <ItemsPresenter x:Name=\"ItemsPresenter\" KeyboardNavigation.DirectionalNavigation=\"Contained\"/>
                                    </ScrollViewer>
                                </Border>
                            </Popup>
                        </Grid>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Custom TextBox Style -->
        <Style TargetType=\"TextBox\">
            <Setter Property=\"Background\" Value=\"#2D2D2D\"/>
            <Setter Property=\"Foreground\" Value=\"#FFFFFF\"/>
            <Setter Property=\"BorderBrush\" Value=\"#404040\"/>
            <Setter Property=\"BorderThickness\" Value=\"1\"/>
            <Setter Property=\"Padding\" Value=\"10,6\"/>
            <Setter Property=\"Template\">
                <Setter.Value>
                    <ControlTemplate TargetType=\"TextBox\">
                        <Border x:Name=\"border\" Background=\"{TemplateBinding Background}\" 
                                BorderBrush=\"{TemplateBinding BorderBrush}\" 
                                BorderThickness=\"{TemplateBinding BorderThickness}\" 
                                CornerRadius=\"6\">
                            <ScrollViewer x:Name=\"PART_ContentHost\" Focusable=\"false\" HorizontalScrollBarVisibility=\"Hidden\" VerticalScrollBarVisibility=\"Hidden\"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Grid Margin=\"24\">
        <Grid.RowDefinitions>
            <RowDefinition Height=\"Auto\"/>
            <RowDefinition Height=\"*\"/>
            <RowDefinition Height=\"Auto\"/>
            <RowDefinition Height=\"Auto\"/>
        </Grid.RowDefinitions>

        <!-- Header -->
        <StackPanel Grid.Row=\"0\" Margin=\"0,0,0,18\">
            <TextBlock Text=\"Repository Refresh\" FontSize=\"22\" FontWeight=\"SemiBold\" Foreground=\"#FFFFFF\"/>
            <TextBlock Text=\"Fetch and sync latest updates from remote repository\" FontSize=\"12\" Foreground=\"#A0A0A0\" Margin=\"0,2,0,0\"/>
        </StackPanel>

        <!-- Local Status Preview -->
        <StackPanel Grid.Row=\"1\" Margin=\"0,0,0,16\">
            <TextBlock Text=\"Local Status Overview\" FontSize=\"12\" FontWeight=\"Medium\" Foreground=\"#D0D0D0\" Margin=\"0,0,0,6\"/>
            <Border Background=\"#202020\" BorderBrush=\"#383838\" BorderThickness=\"1\" CornerRadius=\"8\" Padding=\"12\">
                <ScrollViewer Height=\"90\" VerticalScrollBarVisibility=\"Auto\">
                    <TextBlock Name=\"StatusBox\" Text=\"$formatted_status\" FontSize=\"11\" FontFamily=\"Cascadia Code, Consolas\" Foreground=\"#76B9ED\"/>
                </ScrollViewer>
            </Border>
        </StackPanel>

        <!-- Configuration Grid -->
        <Grid Grid.Row=\"2\" Margin=\"0,0,0,24\">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width=\"*\"/>
                <ColumnDefinition Width=\"16\"/>
                <ColumnDefinition Width=\"*\"/>
            </Grid.ColumnDefinitions>

            <!-- Target Branch -->
            <StackPanel Grid.Column=\"0\">
                <TextBlock Text=\"Source Branch\" FontSize=\"12\" FontWeight=\"Medium\" Foreground=\"#D0D0D0\" Margin=\"0,0,0,6\"/>
                <TextBox Name=\"TargetBranch\" Text=\"$current_branch\" Height=\"34\" VerticalContentAlignment=\"Center\" FontSize=\"12\"/>
            </StackPanel>

            <!-- Refresh Mode -->
            <StackPanel Grid.Column=\"2\">
                <TextBlock Text=\"Refresh Action\" FontSize=\"12\" FontWeight=\"Medium\" Foreground=\"#D0D0D0\" Margin=\"0,0,0,6\"/>
                <ComboBox Name=\"PullMode\" Height=\"34\" SelectedIndex=\"0\" FontSize=\"12\" VerticalContentAlignment=\"Center\">
                    <ComboBoxItem Content=\"Standard Pull\"/>
                    <ComboBoxItem Content=\"Pull --rebase\"/>
                    <ComboBoxItem Content=\"Hard Reset (Force Sync)\"/>
                </ComboBox>
            </StackPanel>
        </Grid>

        <!-- Action Bar -->
        <Grid Grid.Row=\"3\">
            <StackPanel Orientation=\"Horizontal\" HorizontalAlignment=\"Right\">
                <Button Name=\"CancelBtn\" Content=\"Cancel\" Width=\"90\" Height=\"34\" Margin=\"0,0,10,0\">
                    <Button.Template>
                        <ControlTemplate TargetType=\"Button\">
                            <Border Background=\"#2D2D2D\" BorderBrush=\"#404040\" BorderThickness=\"1\" CornerRadius=\"6\">
                                <ContentPresenter HorizontalAlignment=\"Center\" VerticalAlignment=\"Center\"/>
                            </Border>
                        </ControlTemplate>
                    </Button.Template>
                </Button>
                <Button Name=\"SyncBtn\" Content=\"Sync Now\" Width=\"120\" Height=\"34\" IsDefault=\"True\" Foreground=\"#FFFFFF\" FontWeight=\"SemiBold\">
                    <Button.Template>
                        <ControlTemplate TargetType=\"Button\">
                            <Border Background=\"#0067C0\" CornerRadius=\"6\">
                                <ContentPresenter HorizontalAlignment=\"Center\" VerticalAlignment=\"Center\"/>
                            </Border>
                        </ControlTemplate>
                    </Button.Template>
                </Button>
            </StackPanel>
        </Grid>
    </Grid>
</Window>
'@

\$reader = (New-Object System.Xml.XmlNodeReader ([xml]\$xml))
\$window = [System.Windows.Markup.XamlReader]::Load(\$reader)

\$window.Add_Loaded({
    \$helper = New-Object System.Windows.Interop.WindowInteropHelper(\$window)
    [WinEffects]::ApplyTheme(\$helper.Handle)
})

\$targetBranch = \$window.FindName('TargetBranch')
\$pullMode = \$window.FindName('PullMode')
\$syncBtn = \$window.FindName('SyncBtn')
\$cancelBtn = \$window.FindName('CancelBtn')

\$syncBtn.Add_Click({ 
    \$window.DialogResult = \$true
    \$window.Close() 
})

\$cancelBtn.Add_Click({ \$window.Close() })

if (\$window.ShowDialog() -eq \$true) {
    Write-Output \"BRANCH:\$(\$targetBranch.Text)\"
    Write-Output \"MODE:\$(\$pullMode.SelectedIndex)\"
}
")

# 3. Parse PowerShell Output
target_branch=$(echo "$gui_output" | grep "^BRANCH:" | sed 's/^BRANCH://' | tr -d '\r')
pull_mode=$(echo "$gui_output" | grep "^MODE:" | sed 's/^MODE://' | tr -d '\r')

if [ -z "$target_branch" ]; then
    echo "Sync cancelled: Operation aborted."
    read -p "Press Enter to exit..."
    exit 1
fi

# 4. Execute Selected Refresh Workflow
echo ""
echo "------------------------------------------------------"
echo "Fetching updates from origin/$target_branch..."
echo "------------------------------------------------------"

case $pull_mode in
    0)
        # Standard Git Pull
        git pull origin "$target_branch"
        ;;
    1)
        # Rebase Pull
        git pull --rebase origin "$target_branch"
        ;;
    2)
        # Hard Force Refresh (Overwrites local changes with remote HEAD)
        echo "Performing Hard Reset to match origin/$target_branch..."
        git fetch origin "$target_branch"
        git reset --hard "origin/$target_branch"
        ;;
esac

# 5. Keep terminal open
echo "------------------------------------------------------"
echo "Process complete!"
read -p "Press Enter to close terminal..."