Add-Type -AssemblyName System.Windows.Forms, System.Drawing

$GitExe = "C:\Users\332651\Downloads\PortableGit\cmd\git.exe"

# Authentic Windows 8.1 Tile Group Palette
$ColorPurple  = [System.Drawing.Color]::FromArgb(70, 23, 180)    # Inspect Group
$ColorTeal    = [System.Drawing.Color]::FromArgb(0, 171, 169)    # Branching Group
$ColorCrimson = [System.Drawing.Color]::FromArgb(216, 0, 115)   # Stage/Commit Group
$ColorBlue    = [System.Drawing.Color]::FromArgb(45, 137, 239)   # Sync Group
$ColorMango   = [System.Drawing.Color]::FromArgb(250, 104, 0)    # Stash/Clean Group
$BgLight      = [System.Drawing.Color]::White
$DarkText     = [System.Drawing.Color]::FromArgb(30, 30, 30)
$ConsoleBg    = [System.Drawing.Color]::FromArgb(243, 243, 243)

# Native WinAPI for Window Dragging
Add-Type -MemberDefinition @"
    [DllImport("user32.dll")] public static extern bool ReleaseCapture();
    [DllImport("user32.dll")] public static extern int SendMessage(IntPtr hWnd, int Msg, int wParam, int lParam);
"@ -Name "WinAPI" -Namespace "Win32" -ErrorAction SilentlyContinue

# Main Form Window
$script:Form = New-Object System.Windows.Forms.Form
$script:Form.Size = New-Object System.Drawing.Size(860, 620)
$script:Form.StartPosition = "CenterScreen"
$script:Form.BackColor = $BgLight
$script:Form.ForeColor = $DarkText
$script:Form.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$script:Form.FormBorderStyle = "None"

# 1px Metro Window Border
$script:Form.add_Paint({
    param($sender, $e)
    $Pen = New-Object System.Drawing.Pen($ColorPurple, 2)
    $e.Graphics.DrawRectangle($Pen, 0, 0, $script:Form.Width - 1, $script:Form.Height - 1)
    $Pen.Dispose()
})

# Header Panel
$TitlePanel = New-Object System.Windows.Forms.Panel
$TitlePanel.Location = New-Object System.Drawing.Point(1, 1)
$TitlePanel.Size = New-Object System.Drawing.Size(858, 55)
$TitlePanel.BackColor = $BgLight

$TitleText = New-Object System.Windows.Forms.Label
$TitleText.Text = "Git Control Hub"
$TitleText.ForeColor = $ColorPurple
$TitleText.Font = New-Object System.Drawing.Font("Segoe UI Light", 22)
$TitleText.Location = New-Object System.Drawing.Point(20, 10)
$TitleText.AutoSize = $true

$CloseBtn = New-Object System.Windows.Forms.Button
$CloseBtn.Location = New-Object System.Drawing.Point(814, 0)
$CloseBtn.Size = New-Object System.Drawing.Size(44, 36)
$CloseBtn.Text = "X"
$CloseBtn.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 10)
$CloseBtn.ForeColor = $DarkText
$CloseBtn.FlatStyle = "Flat"
$CloseBtn.FlatAppearance.BorderSize = 0
$CloseBtn.add_MouseEnter({ $CloseBtn.BackColor = [System.Drawing.Color]::FromArgb(232, 17, 35); $CloseBtn.ForeColor = [System.Drawing.Color]::White })
$CloseBtn.add_MouseLeave({ $CloseBtn.BackColor = $BgLight; $CloseBtn.ForeColor = $DarkText })
$CloseBtn.Add_Click({ $script:Form.Close() })

$TitlePanel.Controls.AddRange(@($TitleText, $CloseBtn))

# Drag Event
$DragScript = {
    param($sender, $e)
    if ($e.Button -eq "Left") {
        [Win32.WinAPI]::ReleaseCapture()
        [Win32.WinAPI]::SendMessage($script:Form.Handle, 0xA1, 2, 0)
    }
}
$TitlePanel.add_MouseDown($DragScript)
$TitleText.add_MouseDown($DragScript)

# Target Repository Input Row
$RepoLabel = New-Object System.Windows.Forms.Label
$RepoLabel.Location = New-Object System.Drawing.Point(25, 62)
$RepoLabel.Text = "target repository path"
$RepoLabel.Font = New-Object System.Drawing.Font("Segoe UI Light", 11)
$RepoLabel.ForeColor = $DarkText
$RepoLabel.AutoSize = $true

$script:FolderInput = New-Object System.Windows.Forms.TextBox
$script:FolderInput.Location = New-Object System.Drawing.Point(25, 87)
$script:FolderInput.Size = New-Object System.Drawing.Size(710, 25)
$script:FolderInput.Text = "C:\"
$script:FolderInput.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$script:FolderInput.BorderStyle = "FixedSingle"
$script:FolderInput.BackColor = $ConsoleBg

$BrowseBtn = New-Object System.Windows.Forms.Button
$BrowseBtn.Location = New-Object System.Drawing.Point(743, 86)
$BrowseBtn.Size = New-Object System.Drawing.Size(87, 27)
$BrowseBtn.Text = "Browse"
$BrowseBtn.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$BrowseBtn.FlatStyle = "Flat"
$BrowseBtn.FlatAppearance.BorderSize = 0
$BrowseBtn.BackColor = $ColorPurple
$BrowseBtn.ForeColor = [System.Drawing.Color]::White
$BrowseBtn.Add_Click({
    $FolderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    if (Test-Path -LiteralPath $script:FolderInput.Text -PathType Container) {
        $FolderDialog.SelectedPath = $script:FolderInput.Text.Trim()
    }
    if ($FolderDialog.ShowDialog() -eq "OK") { $script:FolderInput.Text = $FolderDialog.SelectedPath }
    $FolderDialog.Dispose()
})

# Execution Helper
function Run-Git ($ArgsString) {
    $targetDir = $script:FolderInput.Text.Trim()
    $script:OutputBox.Text = "Executing: git $ArgsString...`r`n"
    
    if (-not (Test-Path -LiteralPath $targetDir -PathType Container)) {
        $script:OutputBox.Text = "Error: Target folder path does not exist."
        return
    }
    try {
        Push-Location -LiteralPath $targetDir
        $pinfo = New-Object System.Diagnostics.ProcessStartInfo
        $pinfo.FileName = $GitExe
        $pinfo.Arguments = $ArgsString
        $pinfo.RedirectStandardOutput = $true
        $pinfo.RedirectStandardError = $true
        $pinfo.UseShellExecute = $false
        $pinfo.CreateNoWindow = $true

        $p = [System.Diagnostics.Process]::Start($pinfo)
        $stdout = $p.StandardOutput.ReadToEnd()
        $stderr = $p.StandardError.ReadToEnd()
        $p.WaitForExit()

        $script:OutputBox.Text = if ($stderr) { "$stdout`r`n$stderr" } else { $stdout }
    } catch {
        $script:OutputBox.Text = "Error running git:`r`n$_"
    } finally {
        Pop-Location
    }
}

# Metro Category Label Creator
function Add-MetroCategory ($Title, $X, $Y) {
    $Label = New-Object System.Windows.Forms.Label
    $Label.Text = $Title
    $Label.Location = New-Object System.Drawing.Point($X, $Y)
    $Label.Font = New-Object System.Drawing.Font("Segoe UI Light", 12)
    $Label.ForeColor = $DarkText
    $Label.AutoSize = $true
    $script:Form.Controls.Add($Label)
}

# Metro Tile Creator
function Add-MetroTile ($Text, $X, $Y, $W, $H, $BgColor, $ScriptBlock) {
    $Btn = New-Object System.Windows.Forms.Button
    $Btn.Location = New-Object System.Drawing.Point($X, $Y)
    $Btn.Size = New-Object System.Drawing.Size($W, $H)
    $Btn.Text = $Text
    $Btn.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 9)
    $Btn.FlatStyle = "Flat"
    $Btn.FlatAppearance.BorderSize = 0
    $Btn.BackColor = $BgColor
    $Btn.ForeColor = [System.Drawing.Color]::White
    $Btn.TextAlign = "MiddleCenter"

    # Hover effect (lighten slightly)
    $Btn.add_MouseEnter({ $Btn.BackColor = [System.Drawing.Color]::FromArgb([Math]::Min(255, $BgColor.R + 25), [Math]::Min(255, $BgColor.G + 25), [Math]::Min(255, $BgColor.B + 25)) })
    $Btn.add_MouseLeave({ $Btn.BackColor = $BgColor })
    $Btn.Add_Click($ScriptBlock)

    $script:Form.Controls.Add($Btn)
}

# --- GROUP 1: INSPECT (Purple) ---
Add-MetroCategory "inspect" 25 125
Add-MetroTile "Status" 25 152 90 42 $ColorPurple { Run-Git "status -s" }
Add-MetroTile "Log" 120 152 90 42 $ColorPurple { Run-Git "log --oneline -n 10" }
Add-MetroTile "Graph" 25 199 90 42 $ColorPurple { Run-Git "log --graph --oneline --decorate --all -n 10" }
Add-MetroTile "Diff" 120 199 90 42 $ColorPurple { Run-Git "diff" }

# --- GROUP 2: BRANCHING (Teal) ---
Add-MetroCategory "branching" 225 125
Add-MetroTile "List All" 225 152 90 42 $ColorTeal { Run-Git "branch -a" }
Add-MetroTile "Remote Info" 320 152 90 42 $ColorTeal { Run-Git "remote -v" }
Add-MetroTile "Branch Status" 225 199 185 42 $ColorTeal { Run-Git "status -b" }

# --- GROUP 3: STAGE & COMMIT (Crimson) ---
Add-MetroCategory "stage & commit" 425 125
Add-MetroTile "Stage All" 425 152 90 42 $ColorCrimson { Run-Git "add ." }
Add-MetroTile "Unstage" 520 152 90 42 $ColorCrimson { Run-Git "reset" }

$script:CommitInput = New-Object System.Windows.Forms.TextBox
$script:CommitInput.Location = New-Object System.Drawing.Point(425, 199)
$script:CommitInput.Size = New-Object System.Drawing.Size(185, 23)
$script:CommitInput.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$script:CommitInput.Text = "Commit message..."
$script:CommitInput.BorderStyle = "FixedSingle"
$script:CommitInput.BackColor = $ConsoleBg
$script:CommitInput.add_GotFocus({ if ($script:CommitInput.Text -eq "Commit message...") { $script:CommitInput.Text = "" } })

Add-MetroTile "Commit Changes" 425 225 185 30 $ColorCrimson { 
    $msg = $script:CommitInput.Text.Trim()
    if ($msg -eq "" -or $msg -eq "Commit message...") {
        $script:OutputBox.Text = "Error: Please enter a commit message above!"
    } else {
        Run-Git "commit -m `"$msg`""
    }
}

# --- GROUP 4: SYNC & STASH (Blue / Mango) ---
Add-MetroCategory "sync & stash" 625 125
Add-MetroTile "Fetch" 625 152 90 42 $ColorBlue { Run-Git "fetch --all" }
Add-MetroTile "Pull" 720 152 90 42 $ColorBlue { Run-Git "pull" }
Add-MetroTile "Stash" 625 199 90 42 $ColorMango { Run-Git "stash" }
Add-MetroTile "Pop Stash" 720 199 90 42 $ColorMango { Run-Git "stash pop" }

# Bottom Console Screen
$script:OutputBox = New-Object System.Windows.Forms.TextBox
$script:OutputBox.Location = New-Object System.Drawing.Point(25, 275)
$script:OutputBox.Size = New-Object System.Drawing.Size(805, 315)
$script:OutputBox.Multiline = $true
$script:OutputBox.ScrollBars = "Vertical"
$script:OutputBox.Font = New-Object System.Drawing.Font("Consolas", 10)
$script:OutputBox.BorderStyle = "FixedSingle"
$script:OutputBox.BackColor = $ConsoleBg
$script:OutputBox.ForeColor = $DarkText
$script:OutputBox.Text = "Ready to receive commands."

$script:Form.Controls.AddRange(@($TitlePanel, $RepoLabel, $script:FolderInput, $BrowseBtn, $script:CommitInput, $script:OutputBox))

[void]$script:Form.ShowDialog()
$script:Form.Dispose()