#!/usr/bin/env bash
set -euo pipefail

# ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
# Install Script
#
# Categories:
#   - Development
#   - Editors
#   - Utilities
#   - Security
#   - Desktop
#   - Fonts
#   - Networking
#
# Usage:
#   ./install.sh            # Interactive install
#   ./install.sh --all      # Install all without prompts
#   ./install.sh --dry-run  # Preview actions without making changes
# ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

ALL=false
DRY_RUN=false

PACKAGES=(
  # ───────────────────────── Development ─────────────────────────
  git
  cargo
  gcc gcc-c++
  make cmake pkg-config
  python3 python3-pip
  java-17-openjdk-devel maven
  nodejs npm
  podman podman-compose
  sqlite

  # ───────────────────────── Editors ─────────────────────────
  vim neovim

  # ───────────────────────── Utilities ─────────────────────────
  tree tmux htop fzf ripgrep fd-find curl wget unzip tar bleachbit

  # ───────────────────────── Security ─────────────────────────
  gnupg2 openssl keychain

  # ───────────────────────── Desktop ─────────────────────────
  gnome-tweaks gnome-extensions-app ffmpeg ImageMagick

  # ───────────────────────── Fonts ─────────────────────────
  fonts-firacode fonts-jetbrains-mono

  # ───────────────────────── Networking ─────────────────────────
  openssh-clients traceroute nmap
)

# ――――――――――――――――――――――――― Functions ―――――――――――――――――――――――――

# Prints usage help and exits.
usage() {
    cat <<EOF
Usage: $0 [--all] [--dry-run]

  --all       Install all without prompts
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

# Asks the user whether to install a given category unless --all option is set.
ask() {
    local PROMPT=$1
    if $ALL; then
        return 0
    fi
    read -rp "$PROMPT [y/N]: " answer
    [[ "$answer" =~ ^[Yy]$ ]]
}

# Installs a list of packages via dnf.
install_packages() {
    local CATEGORY=$1
    shift
    local PACKS=("$@")
    if ask "Install $CATEGORY packages (${PACKS[*]})?"; then
        echo "[*] Installing $CATEGORY..."
        run_cmd sudo dnf install -y "${PACKS[@]}"
    fi
}

# Updates all system packages.
update_system() {
    if ask "Run full system update?"; then
        echo "[*] Updating system packages..."
        run_cmd sudo dnf upgrade -y
    fi
}

# ――――――――――――――――――――――――― Main routine ―――――――――――――――――――――――――
run() {
    install_packages "Development"  git cargo gcc gcc-c++ make cmake pkg-config python3 python3-pip java-17-openjdk-devel maven nodejs npm podman podman-compose sqlite
    install_packages "Editors"      vim neovim
    install_packages "Utilities"    tree tmux htop fzf ripgrep fd-find curl wget unzip tar bleachbit
    install_packages "Security"     gnupg2 openssl keychain
    install_packages "Desktop"      gnome-tweaks gnome-extensions-app ffmpeg ImageMagick
    install_packages "Fonts"        fonts-firacode fonts-jetbrains-mono
    install_packages "Networking"   openssh-clients traceroute nmap
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
