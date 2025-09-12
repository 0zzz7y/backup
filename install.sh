#!/usr/bin/env bash
set -euo pipefail

# ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
# Install script
#
# Installs predefined packages via dnf, grouped by categories.
#
# Categories:
#   - Development essentials
#   - Editors
#   - System & shell utilities
#   - Security & encryption
#   - Desktop & daily use
#   - Fonts
#   - Networking
#
# Usage:
#   ./install.sh           # Interactive install of all categories
#   ./install.sh --all     # Install all without prompts
#   ./install.sh --dry-run # Preview actions without executing
# ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

ALL=false
DRY_RUN=false

PACKAGES=(
  # ───────────────────────── Development essentials ─────────────────────────
  git gcc gcc-c++ make cmake pkg-config
  python3 python3-pip
  java-17-openjdk-devel maven
  nodejs npm
  podman podman-compose
  sqlite

  # ───────────────────────── Editors ─────────────────────────
  vim neovim

  # ───────────────────────── System & shell utilities ─────────────────────────
  tree tmux htop fzf ripgrep fd-find curl wget unzip tar

  # ───────────────────────── Security & encryption ─────────────────────────
  gnupg2 openssl keychain

  # ───────────────────────── Desktop & daily use ─────────────────────────
  gnome-tweaks gnome-extensions-app ffmpeg ImageMagick

  # ───────────────────────── Fonts ─────────────────────────
  fonts-firacode fonts-jetbrains-mono

  # ───────────────────────── Networking ─────────────────────────
  openssh-clients traceroute nmap
)

# ――――――――――――――――――――――――― Functions ―――――――――――――――――――――――――

## Prints usage help and exits.
usage() {
    cat <<EOF
Usage: $0 [--all] [--dry-run]

  --all       Install all packages without prompts
  --dry-run   Show what would be done without executing commands
EOF
    exit 1
}

## Runs a command, optionally in dry-run mode.
run_cmd() {
    if $DRY_RUN; then
        echo "[dry-run] $*"
    else
        "$@"
    fi
}

## Prompts the user for yes/no confirmation unless --all is set.
ask() {
    local PROMPT=$1
    if $ALL; then
        return 0
    fi
    read -rp "$PROMPT [y/N]: " answer
    [[ "$answer" =~ ^[Yy]$ ]]
}

## Installs a list of packages via dnf.
install_packages() {
    local CATEGORY=$1
    shift
    local PACKS=("$@")
    if ask "Install $CATEGORY packages (${PACKS[*]})?"; then
        echo "[*] Installing $CATEGORY..."
        run_cmd sudo dnf install -y "${PACKS[@]}"
    fi
}

## Updates all system packages.
update_system() {
    if ask "Run full system update?"; then
        echo "[*] Updating system packages..."
        run_cmd sudo dnf upgrade -y
    fi
}

## Main routine: installs all categories and updates the system.
run() {
    install_packages "Development essentials" git gcc gcc-c++ make cmake pkg-config python3 python3-pip java-17-openjdk-devel maven nodejs npm podman podman-compose sqlite
    install_packages "Editors" vim neovim
    install_packages "System & shell utilities" tree tmux htop fzf ripgrep fd-find curl wget unzip tar
    install_packages "Security & encryption" gnupg2 openssl keychain
    install_packages "Desktop & daily use" gnome-tweaks gnome-extensions-app ffmpeg ImageMagick
    install_packages "Fonts" fonts-firacode fonts-jetbrains-mono
    install_packages "Networking" openssh-clients traceroute nmap
    update_system
    echo "[*] Installation complete."
}

# ――――――――――――――――――――――――― Parse arguments ―――――――――――――――――――――――――
while [[ $# -gt 0 ]]; do
    case $1 in
        --all) ALL=true; shift ;;
        --dry-run) DRY_RUN=true; shift ;;
        *) usage ;;
    esac
done

# ――――――――――――――――――――――――― Run ―――――――――――――――――――――――――
run
