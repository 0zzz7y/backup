#!/usr/bin/env bash
set -euo pipefail

# ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
# Cleanup Script
#
# Categories:
#   - BleachBit
#   - Package Manager
#   - Kernels
#   - Logs & Journals
#   - Snapshots
#   - Containers
#
# Usage:
#   ./cleanup.sh            # Interactive cleanup
#   ./cleanup.sh --all      # Cleanup all without prompts
#   ./cleanup.sh --dry-run  # Preview actions without making changes
# ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

ALL=false
DRY_RUN=false

BLEACHBIT_CLEANERS=(
  bash.history bash.tmp
  deepscan.backup deepscan.ds_store deepscan.thumbs_db deepscan.tmp deepscan.vim_swap
  discord.cache discord.cookies discord.history discord.vacuum
  firefox.backup firefox.cache firefox.cookies firefox.crash_reports firefox.dom
  firefox.formhistory firefox.passwords firefox.session_restore firefox.sitepreferences
  firefox.url_history firefox.vacuum
  system.cache system.clipboard system.custom system.desktop_entry system.free_disk_space
  system.localizations system.memory system.recent_documents system.rotated_logs
  system.tmp system.trash
)

# ――――――――――――――――――――――――― Functions ―――――――――――――――――――――――――

# Prints usage help and exits.
usage() {
    cat <<EOF
Usage: $0 [--all] [--dry-run]

  --all       Cleanup all without prompts
  --dry-run   Preview actions without making changes
EOF
    exit 1
}

# Runs a command or prints it if dry-run mode.
run_cmd() {
    if $DRY_RUN; then
        echo "[dry-run] $*"
    else
        "$@"
    fi
}

# Asks the user whether to run a given cleanup unless --all option is set.
ask() {
    local PROMPT=$1
    if $ALL; then
        return 0
    fi
    read -rp "$PROMPT [y/N]: " answer
    [[ "$answer" =~ ^[Yy]$ ]]
}

# Detects package manager.
detect_pkg_manager() {
    if command -v dnf >/dev/null 2>&1; then
        echo "dnf"
    elif command -v apt >/dev/null 2>&1; then
        echo "apt"
    elif command -v pacman >/dev/null 2>&1; then
        echo "pacman"
    else
        echo "unknown"
    fi
}

PKG_MANAGER="$(detect_pkg_manager)"

# ───────────────────────── BleachBit ─────────────────────────
cleanup_bleachbit() {
    if ask "Run BleachBit cleanup for user?"; then
        run_cmd bleachbit --clean "${BLEACHBIT_CLEANERS[@]}"
    fi
    
    if ask "Run BleachBit cleanup for system (sudo)?"; then
        run_cmd sudo bleachbit --clean "${BLEACHBIT_CLEANERS[@]}"
    fi
}

# ───────────────────────── Package Manager ─────────────────────────
cleanup_pkg_manager() {
    case "$PKG_MANAGER" in
        dnf)
            if ask "Clean dnf cache?"; then
                run_cmd sudo dnf clean all
            fi
            if ask "Remove orphaned packages?"; then
                run_cmd sudo dnf autoremove -y
            fi
            ;;
        apt)
            if ask "Clean apt cache?"; then
                run_cmd sudo apt clean
            fi
            if ask "Remove unused packages?"; then
                run_cmd sudo apt autoremove -y
            fi
            ;;
        pacman)
            if ask "Clean pacman cache (paccache -r)?"; then
                run_cmd sudo paccache -r
            fi
            if ask "Remove orphaned packages?"; then
                run_cmd sudo pacman -Rns \$(pacman -Qdtq 2>/dev/null || true) --noconfirm || true
            fi
            ;;
        *)
            echo "[info] No supported package manager found."
            ;;
    esac
}

# ───────────────────────── Kernels ─────────────────────────
cleanup_kernels() {
    case "$PKG_MANAGER" in
        dnf)
            if ask "Remove old kernels (keep 2 newest)?"; then
                run_cmd sudo dnf remove \$(dnf repoquery --installonly --latest-limit=-2 -q) -y || true
            fi
            ;;
        apt)
            if ask "Purge old kernels?"; then
                run_cmd sudo apt --purge autoremove -y
            fi
            ;;
        pacman)
            echo "[info] Pacman does not manage kernel versions the same way."
            ;;
    esac
}

# ───────────────────────── Logs & Journals ─────────────────────────
cleanup_logs() {
    if ask "Vacuum journalctl logs older than 7 days?"; then
        run_cmd sudo journalctl --vacuum-time=7d
    fi

    if ask "Force logrotate?"; then
        run_cmd sudo logrotate --force /etc/logrotate.conf || true
    fi
}

# ───────────────────────── Snapshots ─────────────────────────
cleanup_snapshots() {
    if command -v timeshift >/dev/null 2>&1; then
        if ask "List Timeshift snapshots?"; then
            run_cmd sudo timeshift --list
        fi
    fi

    if command -v snapper >/dev/null 2>&1; then
        if ask "List Snapper snapshots?"; then
            run_cmd sudo snapper list
        fi
    fi
}

# ───────────────────────── Containers ─────────────────────────
cleanup_containers() {
    if command -v docker >/dev/null 2>&1; then
        if ask "Prune Docker (remove stopped containers, unused images, networks, build cache)?"; then
            run_cmd docker system prune -af
        fi
    fi

    if command -v podman >/dev/null 2>&1; then
        if ask "Prune Podman (remove stopped containers, unused images, volumes)?"; then
            run_cmd podman system prune -af
        fi
    fi

    if command -v flatpak >/dev/null 2>&1; then
        if ask "Remove unused Flatpak runtimes?"; then
            run_cmd flatpak uninstall --unused -y
        fi
    fi
}

# ――――――――――――――――――――――― Main routine ―――――――――――――――――――――――
run() {
    cleanup_bleachbit
    cleanup_pkg_manager
    cleanup_kernels
    cleanup_logs
    cleanup_snapshots
    cleanup_containers
    echo "[*] Cleanup complete."
    if $DRY_RUN; then
        echo "[note] This was a dry-run. No destructive changes were performed."
    fi
}

# ――――――――――――――――――――――― Parse arguments ―――――――――――――――――――――――
while [[ $# -gt 0 ]]; do
    case $1 in
        --all) ALL=true; shift ;;
        --dry-run) DRY_RUN=true; shift ;;
        *) usage ;;
    esac
done

# ――――――――――――――――――――――― Run ―――――――――――――――――――――――
run
