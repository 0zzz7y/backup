#!/usr/bin/env bash
set -euo pipefail

# ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
# Install Script
#
# Categories:
#   - Development
#   - Network
#   - Security
#   - Utility
#   - Desktop
#   - Editor
#   - Font
#
# Usage:
#   ./install.sh            # Interactive install
#   ./install.sh --all      # Install all without prompts
#   ./install.sh --dry-run  # Preview actions without making changes
# ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

ALL=false
DRY_RUN=false

DEVELOPMENT_PACKAGES=(
  git
  cargo
  gcc gcc-c++
  make cmake pkg-config
  python3 python3-pip
  java-17-openjdk-devel maven
  nodejs npm pnpm
  podman podman-compose
  sqlite
)

NETWORK_PACKAGES=(
  openssh-clients traceroute nmap
)

SECURITY_PACKAGES=(
  gnupg2 openssl keychain
)

UTILITY_PACKAGES=(
  htop tmux ripgrep fzf tree fd-find curl wget p7zip tar unzip bleachbit
)

DESKTOP_PACKAGES=(
  gnome-tweaks gnome-extensions-app ffmpeg ImageMagick
)

EDITOR_PACKAGES=(
  vim neovim
)

FONT_PACKAGES=(
  fonts-firacode fonts-jetbrains-mono
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
    install_packages "Development"  "${DEVELOPMENT_PACKAGES[@]}"
    install_packages "Network"      "${NETWORK_PACKAGES[@]}"
    install_packages "Security"     "${SECURITY_PACKAGES[@]}"
    install_packages "Utility"      "${UTILITY_PACKAGES[@]}"
    install_packages "Desktop"      "${DESKTOP_PACKAGES[@]}"
    install_packages "Editor"       "${EDITOR_PACKAGES[@]}"
    install_packages "Font"         "${FONT_PACKAGES[@]}"
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
