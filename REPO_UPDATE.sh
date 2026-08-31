#!/bin/bash
# ======================================================
# Shell script that checks every file in this repo
# and pushes it to the main repository located on github
# Created 8/26/2026
# Updated 8/31/2026 with Dynamic Popup Input
# ======================================================

# 1. Open the popup window to ask for your commit message
commit_message=$(powershell.exe -Command "[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic'); [Microsoft.VisualBasic.Interaction]::InputBox('Enter your git commit message:', 'Git Commit Input')")

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
