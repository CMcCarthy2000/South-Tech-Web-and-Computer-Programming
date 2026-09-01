#!/bin/bash
# Advanced Git Control Center For Linux (Terminal Edition)

# Get the current branch or default to main
current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")

# Get a summary of changes
status_summary=$(git status --short 2>/dev/null)

if [ -z "$status_summary" ]; then
    echo "No changes detected in repository."
    read -p "Press Enter to exit..."
    exit 0
fi

# Visual header
echo "========================================="
echo "           GIT CONTROL CENTER            "
echo "========================================="
echo ""

# Display Staged/Unstaged Files Preview
echo "Staged/Unstaged Files Preview:"
echo "$status_summary" | awk '{print " • " $0}'
echo "-----------------------------------------"

# 1. Prompt for Commit Message
echo ""
read -p "Enter Commit Message: " commit_message

if [ -z "$commit_message" ]; then
    echo "Push cancelled: Commit message cannot be empty."
    read -p "Press Enter to exit..."
    exit 1
fi

# 2. Prompt for Target Branch (Defaults to current branch)
echo ""
read -p "Enter Target Branch [Default: $current_branch]: " target_branch
if [ -z "$target_branch" ]; then
    target_branch=$current_branch
fi

# 3. Prompt for Sync Strategy
echo ""
echo "Select Sync Strategy:"
echo "  [1] Rebase (Recommended)"
echo "  [2] Merge"
echo "  [3] Force Push (Caution)"
echo ""
read -p "Enter choice (1-3) [Default: 1]: " strategy_choice

# Default to choice 1 if user just presses Enter
if [ -z "$strategy_choice" ]; then
    strategy_choice=1
fi

echo ""
echo "Processing Git Operations..."
echo "-----------------------------------------"

# Stage all changes and commit
git add .
git commit -m "$commit_message"

# Execute sync and deployment strategy
echo "Syncing with remote branch '$target_branch'..."
case $strategy_choice in
    1)
        git pull --rebase origin "$target_branch"
        git push origin "$target_branch"
        ;;
    2)
        git pull origin "$target_branch" --no-rebase
        git push origin "$target_branch"
        ;;
    3)
        echo "Caution: Force push selected."
        git push origin "$target_branch" --force
        ;;
    *)
        echo "Invalid selection. Defaulting to standard push."
        git push origin "$target_branch"
        ;;
esac

echo "-----------------------------------------"
echo "Process complete!"
read -p "Press Enter to close terminal..."
