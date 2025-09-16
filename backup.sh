#!/usr/bin/env bash
set -euo pipefail

# ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
# Backup Script
#
# Backed up items:
#   - Flatpak apps list
#   - ~/.var/app
#   - ~/.config
#   - ~/.local/share
#   - ~/.gitconfig
#   - ~/.themes
#   - ~/.icons
#   - ~/.ssh
#   - ~/.gnupg
#   - GNOME/KDE settings via dconf (dconf-settings.ini)
#
# Usage:
#   ./backup.sh                             # Interactive backup
#   ./backup.sh --all                       # Backup everything without prompts
#   ./backup.sh --encrypt                   # Backup and encrypt with GPG symmetric encryption
#   ./backup.sh --dir /path                 # Backup to custom directory (default: $HOME/Backup)
#   ./backup.sh --dir /path --all --encrypt # Backup everything without prompts with specified directory and encrypt the archive
# ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

ALL=false
ENCRYPT=false
TIMESTAMP=""
BACKUP_DIRECTORY=""
BASE_BACKUP_DIRECTORY="$HOME/Backup"

# ――――――――――――――――――――――――― Functions ―――――――――――――――――――――――――

# Prints usage help and exits.
usage() {
    cat <<EOF
Usage: $0 [--all] [--encrypt] [--dir backup_directory]

  --all         Backup everything without prompts
  --encrypt     Backup and encrypt with GPG symmetric encryption
  --dir /path   Backup to custom directory (default: $HOME/Backup)
EOF
    exit 1
}

# Creates backup directory with timestamp as a name.
create_backup_directory() {
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    BACKUP_DIRECTORY="$BASE_BACKUP_DIRECTORY/$TIMESTAMP"
    mkdir -p "$BACKUP_DIRECTORY/home"
    echo "[*] Backup directory: $BACKUP_DIRECTORY"
}

# Asks the user whether to back up a given item unless --all option is set.
ask_backup() {
    local ITEM_NAME=$1
    if $ALL; then return 0; fi
    read -rp "Do you want to back up ${ITEM_NAME}? [y/N]: " answer
    [[ "$answer" =~ ^[Yy]$ ]]
}

# Exports the list of Flatpak apps to flatpaks.txt.
backup_flatpaks() {
    if command -v flatpak >/dev/null 2>&1; then
        if ask_backup "Flatpak apps"; then
            echo "[*] Exporting Flatpak apps list..."
            flatpak list --app --columns=application > "$BACKUP_DIRECTORY/flatpaks.txt"
        fi
    fi
}

# Backs up a directory to the backup directory, preserving relative path.
backup_directory() {
    local NAME=$1
    local PATH_TO_BACKUP=$2
    if [ -e "$PATH_TO_BACKUP" ]; then
        if ask_backup "$NAME"; then
            echo "[*] Backing up $NAME..."
            rsync -aHAX --delete --relative "$PATH_TO_BACKUP" "$BACKUP_DIRECTORY/home/"
        fi
    fi
}

# Backs up a single file to the backup directory, preserving relative path.
backup_file() {
    local NAME=$1
    local FILE_TO_BACKUP=$2
    if [ -f "$FILE_TO_BACKUP" ]; then
        if ask_backup "$NAME"; then
            echo "[*] Backing up $NAME..."
            rsync -a --relative "$FILE_TO_BACKUP" "$BACKUP_DIRECTORY/home/"
        fi
    fi
}

# Dumps dconf settings to dconf-settings.ini.
backup_dconf() {
    if command -v dconf >/dev/null 2>&1; then
        if ask_backup "GNOME/KDE settings (dconf)"; then
            echo "[*] Dumping dconf settings..."
            dconf dump / > "$BACKUP_DIRECTORY/dconf-settings.ini"
        fi
    fi
}

# Encrypts the backup directory with gpg symmetric encryption.
encrypt_backup() {
    if $ENCRYPT; then
        echo "[*] Encrypting backup..."
        local ARCHIVE="$BASE_BACKUP_DIRECTORY/${TIMESTAMP}.tar.gz"
        tar -czf - -C "$BASE_BACKUP_DIRECTORY" "$TIMESTAMP" | gpg -c > "${ARCHIVE}.gpg"
        echo "[*] Encrypted archive created at: ${ARCHIVE}.gpg"
        rm -rf "$BACKUP_DIRECTORY"
    fi
}

# ───────────────────────── Main Routine ─────────────────────────
run() {
    create_backup_directory
    backup_flatpaks
    backup_directory "Flatpak app data" "$HOME/.var/app"
    backup_directory "Configs"          "$HOME/.config"
    backup_directory "Local share"      "$HOME/.local/share"
    backup_file      "Git config"       "$HOME/.gitconfig"
    backup_directory "Themes"           "$HOME/.themes"
    backup_directory "Icons"            "$HOME/.icons"
    backup_directory "SSH keys"         "$HOME/.ssh"
    backup_directory "GPG keys"         "$HOME/.gnupg"
    backup_dconf
    encrypt_backup
    echo "[*] Backup completed."
}

# ――――――――――――――――――――――――― Parse arguments ―――――――――――――――――――――――――
while [[ $# -gt 0 ]]; do
    case $1 in
        --all) ALL=true; shift ;;
        --encrypt) ENCRYPT=true; shift ;;
        --dir) BASE_BACKUP_DIRECTORY="$2"; shift 2 ;;
        *) usage ;;
    esac
done

# ――――――――――――――――――――――――― Run ―――――――――――――――――――――――――
run
