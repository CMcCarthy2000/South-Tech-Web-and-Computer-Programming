#!/bin/bash
# ======================================================
# Advanced Git Manager & Publisher
# Style: Windows 11 Fluent WPF Design
# Features: Branch selection, File status, Sync modes
# ======================================================

# 1. Gather current Git context
current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
status_summary=$(git status --short 2>/dev/null)

if [ -z "$status_summary" ]; then
    echo "No changes detected in repository."
    read -p "Press Enter to exit..."
    exit 0
fi

# Format git status for display
formatted_status=$(echo "$status_summary" | sed 's/"/\\"/g' | awk '{print "• " $0}')

# 2. Open Windows 11 Fluent Control Panel
gui_output=$(powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

\$xml = @'
<Window xmlns=\"http://schemas.microsoft.com/winfx/2006/xaml/presentation\"
        xmlns:x=\"http://schemas.microsoft.com/winfx/2006/xaml\"
        Title=\"Git Control Center\" Height=\"480\" Width=\"520\" 
        WindowStartupLocation=\"CenterScreen\" ResizeMode=\"NoResize\"
        Background=\"#F3F3F3\" Foreground=\"#1A1A1A\" FontFamily=\"Segoe UI Variable, Segoe UI\">
    <Grid Margin=\"24\">
        <Grid.RowDefinitions>
            <RowDefinition Height=\"Auto\"/>
            <RowDefinition Height=\"Auto\"/>
            <RowDefinition Height=\"*\"/>
            <RowDefinition Height=\"Auto\"/>
            <RowDefinition Height=\"Auto\"/>
            <RowDefinition Height=\"Auto\"/>
        </Grid.RowDefinitions>

        <!-- Header -->
        <StackPanel Grid.Row=\"0\" Margin=\"0,0,0,16\">
            <TextBlock Text=\"Publish Changes\" FontSize=\"20\" FontWeight=\"SemiBold\"/>
            <TextBlock Text=\"Configure commit details and sync preferences\" FontSize=\"12\" Foreground=\"#5D5D5D\" Margin=\"0,2,0,0\"/>
        </StackPanel>

        <!-- Commit Message Input -->
        <StackPanel Grid.Row=\"1\" Margin=\"0,0,0,16\">
            <TextBlock Text=\"Commit Message\" FontSize=\"12\" FontWeight=\"Medium\" Margin=\"0,0,0,6\"/>
            <TextBox Name=\"CommitMsg\" Height=\"36\" VerticalContentAlignment=\"Center\" Padding=\"10,0\" FontSize=\"13\" 
                     Background=\"#FFFFFF\" BorderBrush=\"#D1D1D1\" BorderThickness=\"1\"/>
        </StackPanel>

        <!-- Changes Preview -->
        <StackPanel Grid.Row=\"2\" Margin=\"0,0,0,16\">
            <TextBlock Text=\"Staged Files Preview\" FontSize=\"12\" FontWeight=\"Medium\" Margin=\"0,0,0,6\"/>
            <Border Background=\"#FFFFFF\" BorderBrush=\"#E0E0E0\" BorderThickness=\"1\" CornerRadius=\"4\" Padding=\"8\">
                <ScrollViewer VerticalScrollBarVisibility=\"Auto\" Height=\"100\">
                    <TextBlock Name=\"StatusBox\" Text=\"$formatted_status\" FontSize=\"11\" FontFamily=\"Cascadia Code, Consolas\" Foreground=\"#333333\"/>
                </ScrollViewer>
            </Border>
        </StackPanel>

        <!-- Configuration Options -->
        <Grid Grid.Row=\"3\" Margin=\"0,0,0,20\">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width=\"*\"/>
                <ColumnDefinition Width=\"12\"/>
                <ColumnDefinition Width=\"*\"/>
            </Grid.ColumnDefinitions>

            <!-- Target Branch -->
            <StackPanel Grid.Column=\"0\">
                <TextBlock Text=\"Target Branch\" FontSize=\"12\" FontWeight=\"Medium\" Margin=\"0,0,0,6\"/>
                <TextBox Name=\"TargetBranch\" Text=\"$current_branch\" Height=\"32\" VerticalContentAlignment=\"Center\" Padding=\"8,0\" FontSize=\"12\" 
                         Background=\"#FFFFFF\" BorderBrush=\"#D1D1D1\" BorderThickness=\"1\"/>
            </StackPanel>

            <!-- Pull Strategy -->
            <StackPanel Grid.Column=\"2\">
                <TextBlock Text=\"Sync Strategy\" FontSize=\"12\" FontWeight=\"Medium\" Margin=\"0,0,0,6\"/>
                <ComboBox Name=\"SyncStrategy\" Height=\"32\" SelectedIndex=\"0\" FontSize=\"12\" VerticalContentAlignment=\"Center\">
                    <ComboBoxItem Content=\"Rebase (Recommended)\"/>
                    <ComboBoxItem Content=\"Merge\"/>
                    <ComboBoxItem Content=\"Force Push (Caution)\"/>
                </ComboBox>
            </StackPanel>
        </Grid>

        <!-- Footer Actions -->
        <Border Grid.Row=\"5\" BorderBrush=\"#E5E5E5\" BorderThickness=\"0,1,0,0\" Padding=\"0,16,0,0\">
            <StackPanel Orientation=\"Horizontal\" HorizontalAlignment=\"Right\">
                <Button Name=\"CancelBtn\" Content=\"Cancel\" Width=\"90\" Height=\"32\" Margin=\"0,0,8,0\" 
                        Background=\"#E5E5E5\" Foreground=\"#000000\" BorderThickness=\"0\"/>
                <Button Name=\"PushBtn\" Content=\"Commit &amp; Push\" Width=\"130\" Height=\"32\" IsDefault=\"True\" 
                        Background=\"#0067C0\" Foreground=\"#FFFFFF\" BorderThickness=\"0\" FontWeight=\"SemiBold\"/>
            </StackPanel>
        </Border>
    </Grid>
</Window>
'@

\$reader = (New-Object System.Xml.XmlNodeReader ([xml]\$xml))
\$window = [System.Windows.Markup.XamlReader]::Load(\$reader)

\$commitMsg = \$window.FindName('CommitMsg')
\$targetBranch = \$window.FindName('TargetBranch')
\$syncStrategy = \$window.FindName('SyncStrategy')
\$pushBtn = \$window.FindName('PushBtn')
\$cancelBtn = \$window.FindName('CancelBtn')

\$pushBtn.Add_Click({ 
    if ([string]::IsNullOrWhiteSpace(\$commitMsg.Text)) {
        [System.Windows.MessageBox]::Show('Please enter a commit message.', 'Validation Error', 'OK', 'Warning')
        return
    }
    \$window.DialogResult = \$true
    \$window.Close() 
})

\$cancelBtn.Add_Click({ \$window.Close() })

\$commitMsg.Focus() | Out-Null

if (\$window.ShowDialog() -eq \$true) {
    Write-Output \"MSG:\$(\$commitMsg.Text)\"
    Write-Output \"BRANCH:\$(\$targetBranch.Text)\"
    Write-Output \"STRATEGY:\$(\$syncStrategy.SelectedIndex)\"
}
")

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
        # Rebase
        git pull --rebase origin "$target_branch"
        ;;
    1)
        # Merge
        git pull origin "$target_branch" --no-rebase
        ;;
    2)
        # Force push warning / handle
        echo "Caution: Force push selected."
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