' 1. CHANGE YOUR COMMAND HERE
' (This example opens the Windows Calculator)
Dim MyCommand
MyCommand = "calc.exe"

' 2. CREATE THE POPUP
Dim Response
Response = MsgBox("Do you want to run the command?", vbYesNo + vbQuestion, "Program Launcher")

' 3. RUN IT IF BUTTON IS PRESSED
If Response = vbYes Then
    Dim wshell
    Set wshell = CreateObject("WScript.Shell")
    wshell.Run MyCommand
End If
