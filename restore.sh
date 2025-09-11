#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Interactive Fedora Workstation Restore Script
#
# This script restores a previously created backup of your home directory and
# Flatpak applications. It supports interactive selection of items to restore
# or a one-shot restore of everything using the --all flag.
#
# Features:
#   - Restore from the latest timestamped backup by default
#   - Option to restore from a specific backup folder using -from
#   - Interactive prompts per item or full restore with --all
#
# Usage:
#   ./restore.sh                        # Interactive restore from latest backup
#   ./restore.sh --all                   # Restore everything without prompts
#   ./restore.sh -dir /path              # Specify custom base backup folder
#   ./restore.sh -from /path/to/backup   # Restore from a specific timestamped backup
#   ./restore.sh -from /path --all       # Full restore from specific backup
#
###############################################################################

# Default backup directory
BASE_BACKUP_DIRECTORY=~/Backup
ALL=false
SPECIFIC_DIR=""

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
        -from)
            SPECIFIC_DIR="$2"
            shift 2
            ;;
        *)
            echo "Usage: $0 [-dir backup_directory] [--all] [-from specific_backup_folder]"
            exit 1
            ;;
    esac
done

# Select backup folder
if [[ -n "$SPECIFIC_DIR" ]]; then
    BACKUP_DIRECTORY="$SPECIFIC_DIR"
else
    BACKUP_DIRECTORY=$(ls -dt "$BASE_BACKUP_DIR"/*/ | head -n1)
fi

echo "[*] Restoring from backup folder: $BACKUP_DIRECTORY"

# Function to ask for restore
ask_restore() {
    local ITEM_NAME=$1
    if $ALL; then
        return 0
    fi
    read -rp "Do you want to restore $ITEM_NAME? [y/N]: " answer
    [[ "$answer" =~ ^[Yy]$ ]]
}

# Restore Flatpaks
if [ -f "$BACKUP_DIRECTORY/flatpaks.txt" ] && ask_restore "Flatpak apps"; then
    echo "[*] Enabling Flathub..."
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    echo "[*] Installing Flatpak apps..."
    xargs -a "$BACKUP_DIRECTORY/flatpaks.txt" -r flatpak install -y flathub
fi

# Restore directories
declare -A ITEMS=(
    ["Configs"]=".config"
    ["Local share"]=".local/share"
    ["Themes"]=".themes"
    ["Icons"]=".icons"
    ["Flatpak app data"]=".var/app"
    ["SSH keys"]=".ssh"
)

for NAME in "${!ITEMS[@]}"; do
    SRC="$BACKUP_DIRECTORY/${ITEMS[$NAME]##*/}"
    DEST=~/${ITEMS[$NAME]}
    if [ -e "$SRC" ] && ask_restore "$NAME"; then
        echo "[*] Restoring $NAME..."
        rsync -avh "$SRC" "$DEST"
    fi
done

echo "[*] Restore complete!"
