#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Interactive Fedora Workstation Backup Script
#
# This script allows you to back up key parts of your home directory and
# Flatpak applications. It supports interactive selection of items to backup
# or a one-shot backup of everything using the --all flag. Each backup is
# stored in a timestamped folder (YYYYMMDD_HHMMSS) to allow multiple backups.
#
# Items backed up:
#   - Flatpak apps list
#   - ~/.config
#   - ~/.local/share
#   - ~/.themes
#   - ~/.icons
#   - ~/.var/app (Flatpak app data)
#   - ~/.ssh
#
# Usage:
#   ./backup.sh               # Interactive backup
#   ./backup.sh --all         # Backup everything without prompts
#   ./backup.sh -dir /path    # Specify custom base backup folder
#   ./backup.sh -dir /path --all
#
###############################################################################

# Default backup directory
BASE_BACKUP_DIRECTORY=~/Backup
ALL=false

# Parse optional arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -dir)
            BASE_BACKUP_DIRECTORY="$2"
            shift 2
            ;;
        --all)
            ALL=true
            shift
            ;;
        *)
            echo "Usage: $0 [-dir backup_directory] [--all]"
            exit 1
            ;;
    esac
done

# Create timestamped backup folder
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIRECTORY="$BASE_BACKUP_DIRECTORY/$TIMESTAMP"
mkdir -p "$BACKUP_DIRECTORY"

echo "[*] Backup folder: $BACKUP_DIRECTORY"

# Function to ask for backup
ask_backup() {
    local ITEM_NAME=$1
    if $ALL; then
        return 0
    fi
    read -rp "Do you want to back up $ITEM_NAME? [y/N]: " answer
    [[ "$answer" =~ ^[Yy]$ ]]
}

# Backup Flatpaks
if ask_backup "Flatpak apps" ""; then
    echo "[*] Exporting Flatpak apps list..."
    flatpak list --app --columns=application > "$BACKUP_DIRECTORY/flatpaks.txt"
fi

# Backup directories
declare -A ITEMS=(
    ["Configs"]="~/.config"
    ["Local share"]="~/.local/share"
    ["Themes"]="~/.themes"
    ["Icons"]="~/.icons"
    ["Flatpak app data"]="~/.var/app"
    ["SSH keys"]="~/.ssh"
)

for NAME in "${!ITEMS[@]}"; do
    PATH_EVAL=$(eval echo "${ITEMS[$NAME]}")
    if [ -d "$PATH_EVAL" ]; then
        if ask_backup "$NAME" "$PATH_EVAL"; then
            echo "[*] Backing up $NAME..."
            rsync -avh --delete "$PATH_EVAL" "$BACKUP_DIRECTORY/"
        fi
    fi
done

echo "[*] Backup completed in $BACKUP_DIRECTORY"
