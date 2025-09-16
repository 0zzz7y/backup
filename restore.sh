#!/usr/bin/env bash
set -euo pipefail

# ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
# Restore Script
#
# Items restored:
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
#   ./restore.sh                            # Interactive restore from latest backup
#   ./restore.sh --all                      # Restore everything without prompts
#   ./restore.sh --decrypt file.tar.gz.gpg  # Decrypt archive and restore from it
#   ./restore.sh --dir /path                # Restore from custom backup directory (default: $HOME/Backup)
#   ./restore.sh --from /path/to/backup     # Restore from a specific backup directory
#   ./restore.sh --dry-run                  # Preview restore actions without making changes
# ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

ALL=false
DRY_RUN=false
RSYNC_OPTS="-aHAX --delete"
DECRYPT_FILE=""
SPECIFIC_DIRECTORY=""
BACKUP_DIRECTORY=""
BASE_BACKUP_DIRECTORY="$HOME/Backup"

# ――――――――――――――――――――――――― Functions ―――――――――――――――――――――――――

# Prints usage help and exits.
usage() {
    cat <<EOF
Usage: $0 [--all] [--decrypt file.gpg] [--dir backup_directory] [--from /path] [--dry-run]

  --all             Restore everything without prompts
  --decrypt file    Decrypt archive and restore from it
  --dir /path       Restore from custom backup directory (default: $HOME/Backup)
  --from /path      Restore from a specific backup directory
  --dry-run         Preview restore actions without making changes
EOF
    exit 1
}

# Gets the backup directory, if its encrypted then decrypts it.
get_backup_directory() {
    if [[ -n "$DECRYPT_FILE" ]]; then
        decrypt_backup "$DECRYPT_FILE"
    elif [[ -n "$SPECIFIC_DIRECTORY" ]]; then
        BACKUP_DIRECTORY="$SPECIFIC_DIRECTORY"
    else
        BACKUP_DIRECTORY=$(ls -dt "$BASE_BACKUP_DIRECTORY"/*/ | head -n1)
    fi
}

# Checks for --dry-run flag, if it is set, no changes will be made.
check_dry_run() {
    if $DRY_RUN; then
        RSYNC_OPTS="--dry-run -aHAX --delete"
        echo "[*] Dry-run mode enabled: no changes will be made."
    fi
}

# Asks the user whether to restore a given item unless --all option is set.
ask_restore() {
    local ITEM_NAME=$1
    if $ALL; then return 0; fi
    read -rp "Do you want to restore ${ITEM_NAME}? [y/N]: " answer
    [[ "$answer" =~ ^[Yy]$ ]]
}

# Decrypts the backup directory with gpg symmetric encryption.
decrypt_backup() {
    local FILE=$1
    local TEMP_DIRECTORY
    TEMP_DIRECTORY=$(mktemp -d)
    echo "[*] Decrypting $FILE into $TEMP_DIRECTORY ..."
    gpg -d "$FILE" | tar -xzf - -C "$TEMP_DIRECTORY"
    BACKUP_DIRECTORY=$(find "$TEMP_DIRECTORY" -mindepth 1 -maxdepth 1 -type d | head -n1)
    echo "[*] Using decrypted backup at $BACKUP_DIRECTORY"
}

# Restores the list of Flatpak apps from flatpaks.txt.
restore_flatpaks() {
    if [ -f "$BACKUP_DIRECTORY/flatpaks.txt" ] && ask_restore "Flatpak apps"; then
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
        xargs -a "$BACKUP_DIRECTORY/flatpaks.txt" -r flatpak install -y flathub
    fi
}

# Restores a directory from the backup directory, preserving relative path.
restore_directory() {
    local NAME=$1
    local REL_PATH=$2
    local SRC="$BACKUP_DIRECTORY/home/$REL_PATH"
    local DEST="$HOME/$REL_PATH"
    if [ -e "$SRC" ] && ask_restore "$NAME"; then
        echo "[*] Restoring $NAME..."
        mkdir -p "$DEST"
        rsync $RSYNC_OPTS "$SRC"/ "$DEST"/
    fi
}

# Restores a single file from the backup directory, preserving relative path.
restore_file() {
    local NAME=$1
    local REL_FILE=$2
    local SRC="$BACKUP_DIRECTORY/home/$REL_FILE"
    local DEST="$HOME/$REL_FILE"
    if [ -f "$SRC" ] && ask_restore "$NAME"; then
        echo "[*] Restoring $NAME..."
        mkdir -p "$(dirname "$DEST")"
        rsync $RSYNC_OPTS "$SRC" "$DEST"
    fi
}

# Restores dconf settings from dconf-settings.ini.
restore_dconf() {
    if [ -f "$BACKUP_DIRECTORY/dconf-settings.ini" ] && ask_restore "GNOME/KDE settings (dconf)"; then
        dconf load / < "$BACKUP_DIRECTORY/dconf-settings.ini"
    fi
}

# ――――――――――――――――――――――― Main routine ―――――――――――――――――――――――
run() {
    echo "[*] Restoring from backup directory: $BACKUP_DIRECTORY"
    get_backup_directory
    check_dry_run
    restore_flatpaks
    restore_directory "Flatpak app data"    ".var/app"
    restore_directory "Configs"             ".config"
    restore_directory "Local share"         ".local/share"
    restore_file      "Git config"          ".gitconfig"
    restore_directory "Themes"              ".themes"
    restore_directory "Icons"               ".icons"
    restore_directory "SSH keys"            ".ssh"
    restore_directory "GPG keys"            ".gnupg"
    restore_dconf
    echo "[*] Restore complete!"
    $DRY_RUN && echo "[*] (dry-run: nothing actually changed)"
}

# ――――――――――――――――――――――――― Parse arguments ―――――――――――――――――――――――――
while [[ $# -gt 0 ]]; do
    case $1 in
        --all) ALL=true; shift ;;
        --decrypt) DECRYPT_FILE="$2"; shift 2 ;;
        --dir) BASE_BACKUP_DIRECTORY="$2"; shift 2 ;;
        --from) SPECIFIC_DIRECTORY="$2"; shift 2 ;;
        --dry-run) DRY_RUN=true; shift ;;
        *) usage ;;
    esac
done

# ――――――――――――――――――――――――― Run ―――――――――――――――――――――――――
run
