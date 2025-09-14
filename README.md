# Backup

A set of lightweight Bash scripts for backing up and restoring workstation configurations and installing essential software.

---

## ✦ Backup Script

Backed up items:
- Flatpak apps list (`flatpaks.txt`)
- `~/.var/app`
- `~/.config`
- `~/.local/share`
- `~/.gitconfig`
- `~/.themes`
- `~/.icons`
- `~/.ssh`
- `~/.gnupg`
- GNOME/KDE settings via dconf (`dconf-settings.ini`)

---

### Usage

```bash
./backup.sh             # Interactive backup
./backup.sh --all       # Backup everything without prompts
./backup.sh --encrypt   # Backup and encrypt with GPG symmetric encryption
./backup.sh --dir /path # Backup to custom directory (default: $HOME/Backup)
```

---

## ✦ Restore Script

Restored items:

* Flatpak apps list
* `~/.var/app`
* `~/.config`
* `~/.local/share`
* `~/.gitconfig`
* `~/.themes`
* `~/.icons`
* `~/.ssh`
* `~/.gnupg`
* GNOME/KDE settings via dconf (`dconf-settings.ini`)

---

### Usage

```bash
./restore.sh                            # Interactive restore from latest backup
./restore.sh --all                      # Restore everything without prompts
./restore.sh --decrypt file.tar.gz.gpg  # Decrypt archive and restore from it
./restore.sh --dir /path                # Restore from custom base backup directory
./restore.sh --from /path/to/backup     # Restore from a specific backup directory
./restore.sh --dry-run                  # Preview restore actions without changes
```

---

## ✦ Install Script

Installs predefined packages via `dnf`, grouped by categories.

**Categories:**

* Development
* Editors
* Utilities
* Security
* Desktop
* Fonts
* Networking

---

### Usage

```bash
./install.sh            # Interactive install
./install.sh --all      # Install all without prompts
./install.sh --dry-run  # Preview actions without making changes
```

---

## ✦ Example Workflow

```bash
# Backup and encrypt everything 
./backup.sh --all --encrypt

# Restore everything from encrypted archive
./restore.sh --all --decrypt ~/Backup/YYYYMMDD_HHmmSS.tar.gz.gpg

# Install essential software
./install.sh --all
```

---

## ✦ Why this instead of full backups?

* Small, portable, and human-readable backups
* Fast to reapply on a fresh system
* Works well with cloud storage for personal files
* Easy to audit what is actually saved and restored

---

> Designed for Fedora Workstation, but adaptable to any Linux distro with Flatpak support.
