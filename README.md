# Backup

A pair of lightweight Bash scripts for backing up and restoring your workstation setup.

---

## ✦ Backup Script (`backup.sh`)

Backed up items:
- Flatpak apps list (`flatpaks.txt`)
- `~/.var/app`
- `~/.config`
- `~/.local/share`
- `~/.gitconfig`
- `~/.themes`
- `~/.icons`
- `~/.local/share/fonts`
- `~/.ssh`
- `~/.gnupg`
- GNOME/KDE settings via dconf (`dconf-settings.ini`)

---

### Usage

```bash
./backup.sh                             # Interactive backup
./backup.sh --all                       # Backup everything without prompts
./backup.sh --encrypt                   # Backup and encrypt with GPG symmetric encryption
./backup.sh --dir /path                 # Backup to specified directory (default: $HOME/Backup)
./backup.sh --dir /path --all --encrypt # Backup everything, custom dir, encrypted
````

---

## ✦ Restore Script (`restore.sh`)

Restored items:

* Flatpak apps list
* `~/.var/app`
* `~/.config`
* `~/.local/share`
* `~/.gitconfig`
* `~/.themes`
* `~/.icons`
* `~/.local/share/fonts`
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

## ✦ Notes

* **Encryption** uses `gpg -c` (symmetric mode).
  You'll be asked for a passphrase when encrypting and decrypting.
* **Flatpak apps** are restored from Flathub (`flatpak install -y flathub`).
* **Relative paths preserved**: backup layout mirrors `$HOME`.
* **Dry-run mode** lets you preview restore actions safely before applying changes.

---

## ✦ Example Workflow

```bash
# Backup everything and encrypt
./backup.sh --all --encrypt

# Restore everything from encrypted archive
./restore.sh --decrypt ~/Backup/20250912_153000.tar.gz.gpg --all
```

---

## ✦ Why this instead of full backups?

* Small, portable, and human-readable backups
* Fast to reapply on a fresh system
* Works well with cloud storage for personal files
* Easy to audit what is actually saved and restored

---

> Designed for Fedora Workstation, but adaptable to any Linux distro with Flatpak support.

