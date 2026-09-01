#!/bin/bash
# ======================================================
# Shell script that checks every file in this repo
# and pushes it to the main repository located on github
# Created 8/26/2026
# Updated 9/01/2026 with Windows 11 WPF Popup Input
# ======================================================

# 1. Open a modern Windows 11 styled WPF window for the commit message
commit_message=$(powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

\$xml = @'
<Window xmlns=\"http://schemas.microsoft.com/winfx/2006/xaml/presentation\"
        xmlns:x=\"http://schemas.microsoft.com/winfx/2006/xaml\"
        Title=\"Git Commit\" Height=\"180\" Width=\"420\" 
        WindowStartupLocation=\"CenterScreen\" ResizeMode=\"NoResize\"
        Background=\"#F3F3F3\" Foreground=\"#000000\" FontFamily=\"Segoe UI Variable, Segoe UI\">
    <Grid Margin=\"20\">
        <Grid.RowDefinitions>
            <RowDefinition Height=\"Auto\"/>
            <RowDefinition Height=\"Auto\"/>
            <RowDefinition Height=\"*\"/>
        </Grid.RowDefinitions>
        
        <TextBlock Grid.Row=\"0\" Text=\"Enter your git commit message:\" FontSize=\"13\" Margin=\"0,0,0,10\"/>
        <TextBox Name=\"InputBox\" Grid.Row=\"1\" Height=\"32\" VerticalContentAlignment=\"Center\" Padding=\"6,0\" FontSize=\"13\" Background=\"#FFFFFF\" BorderThickness=\"1\" BorderBrush=\"#CCCCCC\"/>
        
        <StackPanel Grid.Row=\"2\" Orientation=\"Horizontal\" HorizontalAlignment=\"Right\" VerticalAlignment=\"Bottom\">
            <Button Name=\"OkBtn\" Content=\"Commit &amp; Push\" Width=\"110\" Height=\"32\" Margin=\"0,0,8,0\" IsDefault=\"True\" Background=\"#0067C0\" Foreground=\"#FFFFFF\" BorderThickness=\"0\" FontWeight=\"SemiBold\"/>
            <Button Name=\"CancelBtn\" Content=\"Cancel\" Width=\"80\" Height=\"32\" IsCancel=\"True\" Background=\"#E5E5E5\" Foreground=\"#000000\" BorderThickness=\"0\"/>
        </StackPanel>
    </Grid>
</Window>
'@

\$reader = (New-Object System.Xml.XmlNodeReader ([xml]\$xml))
\$window = [System.Windows.Markup.XamlReader]::Load(\$reader)

\$input = \$window.FindName('InputBox')
\$okBtn = \$window.FindName('OkBtn')

\$okBtn.Add_Click({ \$window.DialogResult = \$true; \$window.Close() })

\$input.Focus() | Out-Null
if (\$window.ShowDialog() -eq \$true) {
    Write-Output \$input.Text
}
")

# 2. Clean up any hidden Windows carriage returns (\r)
commit_message=$(echo "$commit_message" | tr -d '\r')

# 3. If you click Cancel or leave it blank, stop the script safely
if [ -z "$commit_message" ]; then
    echo "Push cancelled: No commit message entered."
    exit 1
fi

# 4. Run your original git sequence using your custom input
git add .

git commit -m "$commit_message"

git push