#!/bin/bash
# ======================================================
# Git Command Center Pro
# Style: Windows 11 Native Desktop Acrylic + Dark UI Fix
# ======================================================

set +o histexpand

current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "N/A")
repo_root=$(git rev-parse --show-toplevel 2>/dev/null || echo "Not a Git Repository")
status_summary=$(git status --short 2>/dev/null)
all_branches=$(git branch --format="%(refname:short)" 2>/dev/null)
recent_commits=$(git log -n 6 --oneline 2>/dev/null)
stash_count=$(git stash list 2>/dev/null | wc -l | tr -d ' ')

if [ "$current_branch" = "N/A" ]; then
    echo "Error: Must be executed inside a valid Git repository."
    read -p "Press Enter to exit..."
    exit 1
fi

export GIT_CUR_BRANCH="$current_branch"
export GIT_REPO_ROOT="$repo_root"
export GIT_STATUS_FMT="$(if [ -n "$status_summary" ]; then echo "$status_summary" | awk '{print "• " $0}'; else echo "• Working tree clean"; fi)"
export GIT_ALL_BRANCHES="$all_branches"
export GIT_RECENT_COMMITS="$recent_commits"
export GIT_STASH_COUNT="$stash_count"

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
        int darkMode = 1;
        DwmSetWindowAttribute(hwnd, 20, ref darkMode, sizeof(int));

        MARGINS margins = new MARGINS { cxLeftWidth = -1, cxRightWidth = -1, cyTopHeight = -1, cyBottomHeight = -1 };
        DwmExtendFrameIntoClientArea(hwnd, ref margins);

        int backdrop = 3; 
        DwmSetWindowAttribute(hwnd, 38, ref backdrop, sizeof(int));
    }
}
"@
Add-Type -TypeDefinition $code

$xml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Git Command Center Pro" Height="680" Width="850" 
        WindowStartupLocation="CenterScreen" ResizeMode="NoResize"
        Background="Transparent" Foreground="#FFFFFF" FontFamily="Segoe UI Variable Text, Segoe UI">
    
    <Window.Resources>
        <!-- FIX: Override system colors so ComboBox and internal controls do not default to white -->
        <SolidColorBrush x:Key="{x:Static SystemColors.WindowBrushKey}" Color="#252525" />
        <SolidColorBrush x:Key="{x:Static SystemColors.ControlBrushKey}" Color="#303030" />
        <SolidColorBrush x:Key="{x:Static SystemColors.ControlTextBrushKey}" Color="#FFFFFF" />
        <SolidColorBrush x:Key="{x:Static SystemColors.WindowTextBrushKey}" Color="#FFFFFF" />
    </Window.Resources>

    <Grid Background="#D0101010">
        <Grid Margin="24">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>

            <!-- Header -->
            <StackPanel Grid.Row="0" Margin="0,0,0,16">
                <TextBlock Text="Git Command Center Pro" FontSize="24" FontWeight="SemiBold" Foreground="#FFFFFF"/>
                <TextBlock Name="RepoPath" FontSize="12" Foreground="#A0FFFFFF" Margin="0,2,0,0"/>
            </StackPanel>

            <!-- Main Dashboard (3 Columns) -->
            <Grid Grid.Row="1" Margin="0,0,0,16">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="16"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="16"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>

                <!-- Column 1: Commits -->
                <StackPanel Grid.Column="0">
                    <TextBlock Text="Working Directory" FontSize="13" FontWeight="SemiBold" Foreground="#E0E0E0" Margin="0,0,0,8"/>
                    <Border Background="#20FFFFFF" BorderBrush="#30FFFFFF" BorderThickness="1" CornerRadius="6" Padding="10" Height="140" Margin="0,0,0,14">
                        <ScrollViewer VerticalScrollBarVisibility="Auto">
                            <TextBlock Name="StatusBox" FontSize="11" FontFamily="Cascadia Code, Consolas" Foreground="#76B9ED" TextWrapping="Wrap"/>
                        </ScrollViewer>
                    </Border>

                    <TextBlock Text="Commit Message" FontSize="13" FontWeight="SemiBold" Foreground="#E0E0E0" Margin="0,0,0,8"/>
                    <TextBox Name="CommitMsg" Height="50" TextWrapping="Wrap" AcceptsReturn="True" VerticalContentAlignment="Top" FontSize="12" Padding="8"
                             Background="#30000000" Foreground="#FFFFFF" BorderBrush="#50FFFFFF" BorderThickness="1" Margin="0,0,0,10"/>

                    <Button Name="CommitPushBtn" Content="Commit &amp; Push" Height="34" Background="#0067C0" Foreground="#FFFFFF" BorderThickness="0" FontWeight="SemiBold" Margin="0,0,0,8"/>
                    <Button Name="CommitOnlyBtn" Content="Commit Only" Height="34" Background="#25FFFFFF" Foreground="#FFFFFF" BorderBrush="#40FFFFFF" BorderThickness="1" Margin="0,0,0,8"/>
                    <Button Name="AmendBtn" Content="Amend Last Commit" Height="34" Background="#25FFFFFF" Foreground="#FFFFFF" BorderBrush="#40FFFFFF" BorderThickness="1"/>
                </StackPanel>

                <!-- Column 2: Branches & Sync -->
                <StackPanel Grid.Column="2">
                    <TextBlock Text="Branch Management" FontSize="13" FontWeight="SemiBold" Foreground="#E0E0E0" Margin="0,0,0,8"/>
                    <ComboBox Name="BranchSelect" Height="34" FontSize="12" VerticalContentAlignment="Center" Margin="0,0,0,8"
                              BorderBrush="#40FFFFFF" BorderThickness="1"/>
                    <Button Name="SwitchBtn" Content="Switch to Branch" Height="34" Background="#25FFFFFF" Foreground="#FFFFFF" BorderBrush="#40FFFFFF" BorderThickness="1" Margin="0,0,0,14"/>

                    <TextBlock Text="Create Branch" FontSize="12" Foreground="#D0D0D0" Margin="0,0,0,4"/>
                    <TextBox Name="NewBranchName" Height="34" VerticalContentAlignment="Center" FontSize="12" Padding="8,0,8,0"
                             Background="#30000000" Foreground="#FFFFFF" BorderBrush="#50FFFFFF" BorderThickness="1" Margin="0,0,0,8"/>
                    <Button Name="CreateBranchBtn" Content="Create &amp; Switch" Height="34" Background="#25FFFFFF" Foreground="#FFFFFF" BorderBrush="#40FFFFFF" BorderThickness="1" Margin="0,0,0,18"/>

                    <TextBlock Text="Sync Repository" FontSize="13" FontWeight="SemiBold" Foreground="#E0E0E0" Margin="0,0,0,8"/>
                    <Button Name="PullBtn" Content="Pull (Rebase)" Height="34" Margin="0,0,0,8" Background="#25FFFFFF" Foreground="#FFFFFF" BorderBrush="#40FFFFFF" BorderThickness="1"/>
                    <Button Name="FetchBtn" Content="Fetch Remote" Height="34" Background="#25FFFFFF" Foreground="#FFFFFF" BorderBrush="#40FFFFFF" BorderThickness="1"/>
                </StackPanel>

                <!-- Column 3: Advanced Tools -->
                <StackPanel Grid.Column="4">
                    <TextBlock Text="Advanced Tools" FontSize="13" FontWeight="SemiBold" Foreground="#E0E0E0" Margin="0,0,0,8"/>
                    <Button Name="ViewDiffBtn" Content="View Unstaged Diffs" Height="34" Margin="0,0,0,8" Background="#25FFFFFF" Foreground="#FFFFFF" BorderBrush="#40FFFFFF" BorderThickness="1"/>
                    <Button Name="UndoCommitBtn" Content="Undo Last Commit (Soft)" Height="34" Margin="0,0,0,18" Background="#408B0000" Foreground="#FFFFFF" BorderBrush="#50FFFFFF" BorderThickness="1"/>

                    <TextBlock Text="Stash Options" FontSize="13" FontWeight="SemiBold" Foreground="#E0E0E0" Margin="0,0,0,8"/>
                    <Button Name="StashSaveBtn" Content="Stash Changes" Height="34" Margin="0,0,0,8" Background="#25FFFFFF" Foreground="#FFFFFF" BorderBrush="#40FFFFFF" BorderThickness="1"/>
                    <Button Name="StashPopBtn" Content="Pop Latest Stash" Height="34" Margin="0,0,0,18" Background="#25FFFFFF" Foreground="#FFFFFF" BorderBrush="#40FFFFFF" BorderThickness="1"/>

                    <TextBlock Text="Recent History" FontSize="13" FontWeight="SemiBold" Foreground="#E0E0E0" Margin="0,0,0,8"/>
                    <Border Background="#20FFFFFF" BorderBrush="#30FFFFFF" BorderThickness="1" CornerRadius="6" Padding="10" Height="110">
                        <ScrollViewer VerticalScrollBarVisibility="Auto">
                            <TextBlock Name="CommitLogBox" FontSize="11" FontFamily="Cascadia Code, Consolas" Foreground="#98C379" TextWrapping="Wrap"/>
                        </ScrollViewer>
                    </Border>
                </StackPanel>
            </Grid>

            <!-- Footer Toolbar -->
            <Grid Grid.Row="2">
                <TextBlock Name="FooterInfo" FontSize="12" Foreground="#A0FFFFFF" VerticalAlignment="Center"/>
                <Button Name="CloseBtn" Content="Exit Center" Width="120" Height="34" HorizontalAlignment="Right"
                        Background="#25FFFFFF" Foreground="#FFFFFF" BorderBrush="#40FFFFFF" BorderThickness="1"/>
            </Grid>
        </Grid>
    </Grid>
</Window>
"@

$reader = (New-Object System.Xml.XmlNodeReader ([xml]$xml))
$window = [System.Windows.Markup.XamlReader]::Load($reader)

$window.Add_SourceInitialized({
    $helper = New-Object System.Windows.Interop.WindowInteropHelper($window)
    $hwndSource = [System.Windows.Interop.HwndSource]::FromHwnd($helper.Handle)
    $hwndSource.CompositionTarget.BackgroundColor = [System.Windows.Media.Colors]::Transparent
    [WinEffects]::EnableAcrylic($helper.Handle)
})

# Bindings
$repoPath = $window.FindName("RepoPath")
$statusBox = $window.FindName("StatusBox")
$commitMsg = $window.FindName("CommitMsg")
$branchSelect = $window.FindName("BranchSelect")
$newBranchName = $window.FindName("NewBranchName")
$commitLogBox = $window.FindName("CommitLogBox")
$footerInfo = $window.FindName("FooterInfo")

$repoPath.Text = "DIR: " + $env:GIT_REPO_ROOT
$statusBox.Text = $env:GIT_STATUS_FMT
$commitLogBox.Text = $env:GIT_RECENT_COMMITS
$footerInfo.Text = "Active: " + $env:GIT_CUR_BRANCH + " | Stashes: " + $env:GIT_STASH_COUNT

# Populate Branches
$branches = $env:GIT_ALL_BRANCHES -split "\r?\n"
foreach ($b in $branches) {
    if (-not [string]::IsNullOrWhiteSpace($b)) {
        [void]$branchSelect.Items.Add($b)
        if ($b -eq $env:GIT_CUR_BRANCH) { $branchSelect.SelectedItem = $b }
    }
}

# Actions
$window.FindName("CommitPushBtn").Add_Click({
    if ([string]::IsNullOrWhiteSpace($commitMsg.Text)) { return }
    Write-Output "ACTION:COMMIT_PUSH"; Write-Output "MSG:$($commitMsg.Text)"; $window.Close()
})
$window.FindName("CommitOnlyBtn").Add_Click({
    if ([string]::IsNullOrWhiteSpace($commitMsg.Text)) { return }
    Write-Output "ACTION:COMMIT_ONLY"; Write-Output "MSG:$($commitMsg.Text)"; $window.Close()
})
$window.FindName("AmendBtn").Add_Click({ Write-Output "ACTION:AMEND"; $window.Close() })
$window.FindName("SwitchBtn").Add_Click({ Write-Output "ACTION:SWITCH"; Write-Output "TARG:$($branchSelect.SelectedItem)"; $window.Close() })
$window.FindName("CreateBranchBtn").Add_Click({ Write-Output "ACTION:CREATE_BRANCH"; Write-Output "TARG:$($newBranchName.Text)"; $window.Close() })
$window.FindName("PullBtn").Add_Click({ Write-Output "ACTION:PULL"; $window.Close() })
$window.FindName("FetchBtn").Add_Click({ Write-Output "ACTION:FETCH"; $window.Close() })
$window.FindName("ViewDiffBtn").Add_Click({ Write-Output "ACTION:VIEW_DIFF"; $window.Close() })
$window.FindName("UndoCommitBtn").Add_Click({ Write-Output "ACTION:UNDO_COMMIT"; $window.Close() })
$window.FindName("StashSaveBtn").Add_Click({ Write-Output "ACTION:STASH_SAVE"; $window.Close() })
$window.FindName("StashPopBtn").Add_Click({ Write-Output "ACTION:STASH_POP"; $window.Close() })
$window.FindName("CloseBtn").Add_Click({ Write-Output "ACTION:CANCEL"; $window.Close() })

[void]$window.ShowDialog()
')

action=$(echo "$gui_output" | grep "^ACTION:" | sed 's/^ACTION://' | tr -d '\r')
msg=$(echo "$gui_output" | grep "^MSG:" | sed 's/^MSG://' | tr -d '\r')
targ=$(echo "$gui_output" | grep "^TARG:" | sed 's/^TARG://' | tr -d '\r')

echo ""
echo "------------------------------------------------------"

case "$action" in
    "COMMIT_PUSH")
        git add . && git commit -m "$msg" && git pull --rebase origin "$current_branch" && git push origin "$current_branch" ;;
    "COMMIT_ONLY")
        git add . && git commit -m "$msg" ;;
    "AMEND")
        git commit --amend --no-edit ;;
    "SWITCH")
        git checkout "$targ" ;;
    "CREATE_BRANCH")
        if [ -n "$targ" ]; then git checkout -b "$targ"; else echo "Branch name cannot be empty."; fi ;;
    "PULL")
        git pull --rebase origin "$current_branch" ;;
    "FETCH")
        git fetch --all --prune ;;
    "VIEW_DIFF")
        echo "Opening diff..."
        git diff | less ;;
    "UNDO_COMMIT")
        echo "Undoing last commit (keeping files staged)..."
        git reset --soft HEAD~1 ;;
    "STASH_SAVE")
        git stash save "Stashed via Command Center" ;;
    "STASH_POP")
        git stash pop ;;
    *)
        echo "Exited." ;;
esac

echo "------------------------------------------------------"