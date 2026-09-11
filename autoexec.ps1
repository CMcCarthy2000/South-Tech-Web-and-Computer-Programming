Add-Type -AssemblyName System.Windows.Forms, System.Drawing, Microsoft.VisualBasic.Compatibility

$GitExe = "C:\Users\332651\Downloads\PortableGit\cmd\git.exe"
$Win95Gray = [System.Drawing.Color]::FromArgb(212, 208, 200)

# Native Windows API declarations to pull icons out of DLL resource files
$WinAPI = Add-Type -MemberDefinition @"
    [DllImport("user32.dll", CharSet = CharSet.Auto)] public static extern uint ExtractIconEx(string szFileName, int nIconIndex, IntPtr[] phiconLarge, IntPtr[] phiconSmall, uint nIcons);
    [DllImport("user32.dll")] public static extern bool ReleaseCapture();
    [DllImport("user32.dll")] public static extern int SendMessage(IntPtr hWnd, int Msg, int wParam, int lParam);
"@ -Name "WinAPI" -Namespace "Win32" -PassThru

# Helper function to extract a specific icon index out of a system library file
function Get-SystemIcon($Path, $Index) {
    $Large = New-Object IntPtr[](1)
    $Small = New-Object IntPtr[](1)
    [void]$WinAPI::ExtractIconEx($Path, $Index, $Large, $Small, 1)
    if ($Large[0] -ne [IntPtr]::Zero) { return [System.Drawing.Icon]::FromHandle($Large[0]) }
    return $null
}

# Pull exact Windows 95 icons by their index locations
$PathPif = "C:\Windows\System32\pifmgr.dll"
$PathMor = "C:\Windows\System32\moricons.dll"

$IconStatus = Get-SystemIcon $PathPif 2   # Spinning Ball / Globe
$IconLog    = Get-SystemIcon $PathPif 5   # Wizard Hat
$IconBranch = Get-SystemIcon $PathPif 19  # Network Tree Structure
$IconRemote = Get-SystemIcon $PathMor 4   # Terminal Screen with "DOS" text

# Window Frame Configuration
$Form = New-Object System.Windows.Forms.Form
$Form.Size = "650, 480"; $Form.StartPosition = "CenterScreen"
$Form.BackColor = $Win95Gray; $Form.Font = New-Object System.Drawing.Font("MS Sans Serif", 8.25)
$Form.FormBorderStyle = "None"

$Form.add_Paint({
    param($sender, $e)
    [System.Windows.Forms.ControlPaint]::DrawBorder3D($e.Graphics, $Form.ClientRectangle, "Raised")
})

# Rebuilding a true Windows 95 Dark Blue Title Bar Panel
$TitlePanel = New-Object System.Windows.Forms.Panel
$TitlePanel.Location = "4, 4"; $TitlePanel.Size = "642, 20"
$TitlePanel.BackColor = [System.Drawing.Color]::FromArgb(0, 0, 128)

$TitleText = New-Object System.Windows.Forms.Label
$TitleText.Text = "Portable Control Panel"; $TitleText.ForeColor = [System.Drawing.Color]::White
$TitleText.Font = New-Object System.Drawing.Font("MS Sans Serif", 8.25, "Bold")
$TitleText.Location = "4, 3"; $TitleText.AutoSize = $true

# Perfect Custom Inset close button
$CloseBtn = New-Object System.Windows.Forms.Button
$CloseBtn.Location = "622, 2"; $CloseBtn.Size = "16, 14"; $CloseBtn.BackColor = $Win95Gray
$CloseBtn.FlatStyle = "Standard"
$CloseBtn.add_Paint({
    param($sender, $e)
    $Pen = New-Object System.Drawing.Pen([System.Drawing.Color]::Black, 2)
    $e.Graphics.DrawLine($Pen, 4, 3, 10, 9)
    $e.Graphics.DrawLine($Pen, 4, 9, 10, 3)
    $Pen.Dispose()
})
$CloseBtn.Add_Click({ $Form.Close() })
$TitlePanel.Controls.AddRange(@($TitleText, $CloseBtn))

# Flawless Windows Drag Interaction Event
$DragScript = {
    param($sender, $e)
    if ($e.Button -eq "Left") {
        [void]$WinAPI::ReleaseCapture()
        [void]$WinAPI::SendMessage($Form.Handle, 0xA1, 2, 0)
    }
}
$TitlePanel.add_MouseDown($DragScript)
$TitleText.add_MouseDown($DragScript)

# Left Panel: Git Repository Input Box
$GroupBbox = New-Object System.Windows.Forms.GroupBox
$GroupBbox.Location = "15, 40"; $GroupBbox.Size = "380, 150"; $GroupBbox.Text = "Target Git Repository"

$Label = New-Object System.Windows.Forms.Label
$Label.Location = "15, 30"; $Label.Size = "350, 20"; $Label.Text = "Local path to your project folder:"

$script:FolderInput = New-Object System.Windows.Forms.TextBox
$script:FolderInput.Location = "15, 55"; $script:FolderInput.Size = "255, 25"; $script:FolderInput.Text = "C:\"
$script:FolderInput.BorderStyle = "Fixed3D"

# Classic Vintage Directory Browser Popup
$BrowseBtn = New-Object System.Windows.Forms.Button
$BrowseBtn.Location = "280, 53"; $BrowseBtn.Size = "85, 25"; $BrowseBtn.Text = "Browse..."
$BrowseBtn.FlatStyle = "Standard"
$BrowseBtn.Add_Click({
    $ClassicForm = New-Object System.Windows.Forms.Form
    $ClassicForm.Text = "Select Database Directory"; $ClassicForm.Size = "340, 360"
    $ClassicForm.StartPosition = "CenterParent"; $ClassicForm.BackColor = $Win95Gray
    $ClassicForm.FormBorderStyle = "FixedDialog"; $ClassicForm.MaximizeBox = $false

    $DirBox = New-Object Microsoft.VisualBasic.Compatibility.VB6.DirListBox
    $DirBox.Location = "15, 30"; $DirBox.Size = "190, 200"; $DirBox.Path = $script:FolderInput.Text

    $DriveBox = New-Object Microsoft.VisualBasic.Compatibility.VB6.DriveListBox
    $DriveBox.Location = "15, 265"; $DriveBox.Size = "190, 25"
    $DriveBox.add_SelectedIndexChanged({ try { $DirBox.Path = $DriveBox.Drive } catch {} })

    $OkBtn = New-Object System.Windows.Forms.Button
    $OkBtn.Text = "OK"; $OkBtn.Location = "230, 30"; $OkBtn.DialogResult = "OK"

    $ClassicForm.Controls.AddRange(@($DirBox, $DriveBox, $OkBtn))
    if ($ClassicForm.ShowDialog() -eq "OK") { $script:FolderInput.Text = $DirBox.Path }
})
$GroupBbox.Controls.AddRange(@($Label, $script:FolderInput, $BrowseBtn))

# Bottom Panel: Output Display Screen
$script:OutputBox = New-Object System.Windows.Forms.TextBox
$script:OutputBox.Location = "15, 210"; $script:OutputBox.Size = "620, 250"
$script:OutputBox.Multiline = $true; $script:OutputBox.ScrollBars = "Vertical"
$script:OutputBox.Font = New-Object System.Drawing.Font("Courier New", 9.75)
$script:OutputBox.BorderStyle = "Fixed3D"; $script:OutputBox.Text = "Ready to receive commands."

# Side Panel: Action Command Button Generator
function Create-CmdButton ($Text, $Y, $ArgsString, $WinIcon) {
    $Btn = New-Object System.Windows.Forms.Button
    $Btn.Location = New-Object System.Drawing.Point(415, $Y); $Btn.Size = "220, 32"
    $Btn.Text = "     $Text"; $Btn.FlatStyle = "Standard"; $Btn.TextAlign = "MiddleLeft"
    
    if ($WinIcon -ne $null) {
        $Btn.Image = $WinIcon.ToBitmap()
        $Btn.ImageAlign = "MiddleLeft"
    }

    $Btn.Add_Click({
        $script:OutputBox.Text = "Running Git command... Please wait.`r`n"
        if (-not (Test-Path $script:FolderInput.Text)) {
            $script:OutputBox.Text = "Error: Target folder path does not exist."; return
        }
        try {
            Set-Location $script:FolderInput.Text
            $script:OutputBox.Text = (Invoke-Expression "& '$GitExe' $ArgsString 2>&1" | Out-String)
        } catch { $script:OutputBox.Text = "Error running command:`r`n$_" }
    })
    $Form.Controls.Add($Btn)
}

# Apply icons directly to each button context parameter
Create-CmdButton "Git Status" 48 "status" $IconStatus
Create-CmdButton "Git Log (Last 5)" 85 "log --oneline -n 5" $IconLog
Create-CmdButton "Git Branches" 122 "branch -a" $IconBranch
Create-CmdButton "Git Remotes" 159 "remote -v" $IconRemote

$Form.Controls.AddRange(@($TitlePanel, $GroupBbox, $script:OutputBox))
[void]$Form.ShowDialog()
