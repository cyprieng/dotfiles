# Dotfiles

My dotfiles for macOS.

Some files (for example raycast configuration) are encrypted and can only be decrypted with my private password.
Do not use the dotfiles as-is but as a base for your configuration.

## Initial Setup

If this is your first time setting up this dotfiles repository on a new machine:

### 1. Generate SSH Key

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
# Press Enter to accept default location (~/.ssh/id_ed25519)
# Enter a passphrase (recommended)

# Add SSH key to macOS Keychain (stores passphrase)
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```

### 2. Add SSH Key to GitHub

```bash
# Copy your public key to clipboard
pbcopy < ~/.ssh/id_ed25519.pub
```

Then go to [GitHub SSH Settings](https://github.com/settings/keys) and add your ssh key.

### 3. Clone the Repository

```bash
cd ~
git clone git@github.com:cyprieng/dotfiles.git
cd dotfiles
```

### 4. Install

```bash
make install
```

This will run the full installation process (brew, stow, dependencies, and setup).

## Available Commands

Run `make help` to see all available commands:

- `make install` - Full installation (runs stow, deps, and setup)
- `make stow` - Symlink all dotfiles to your home directory
- `make unstow` - Remove all symlinks
- `make init` - Install brew and stow
- `make deps` - Install all dependencies (Homebrew, Go, Node, Python, Rust packages)
- `make setup` - Configure apps & system settings (decrypt secrets, setup git, apply macOS settings)
- `make extra` - Install extra applications and configurations
- `make update` - Update everything (Homebrew, Node, Python, Rust)
- `make clean` - Clean up broken symlinks and Homebrew cache
- `make backup` - Backup app configurations (AltTab, BetterTouchTool, Raycast)

## Manual process

### macOS Settings

- Reduce animations: Apple menu > System Settings > Accessibility > Motion > Turn on Reduce motion
- Add qwerty-fr: Apple menu > System Settings > Keyboard > Input Sources > Add qwerty-fr from Others
- Hide menu bar items: Apple menu > Menu Bar > Hide everything except Aerospace and AlDente (replace native battery with it)

### Apps on startup

Make sure the following apps run on startup:

- Aerospace
- AlDente
- CleanShotX
- Hammerspoon
- Raycast
- AltTab
- Karabiner
- BetterTouchTool

### Dock

Rearrange Dock:

- Safari
- Chrome
- Claude
- Mail
- Ghostty
- Obsidian

### Zen / Chrome

Install the following chrome extensions:

- [2FAS](https://chromewebstore.google.com/detail/2fas-auth-two-factor-auth/dbfoemgnkgieejfkaddieamagdfepnff)
- [Archive.today](https://chromewebstore.google.com/detail/archivetoday-automator/mmhadhnchpgicjlmlcdfaapkekknnkha)
- [Obsidian Web Clipper](https://chromewebstore.google.com/detail/obsidian-web-clipper/cnjifjpddelmedmihgijeibhnjfabmlf)
- [Old Reddit Redirect](https://chromewebstore.google.com/detail/old-reddit-redirect/dneaehbmnbhcippjikoajpoabadpodje)
- [Proton Pass](https://chromewebstore.google.com/detail/proton-pass-free-password/ghmbeldphafepmbegfdlkpapadhbakde)
- [uBlock Origin Lite](https://chromewebstore.google.com/detail/ublock-origin-lite/ddkjiahejlhfcafbddmgiahcphecmpfh)
- [Vimium](https://chromewebstore.google.com/detail/vimium/dbepggeogbaibhgnhhndojpepiihcmeb)
- [Wayback Machine](https://chromewebstore.google.com/detail/wayback-machine/fpnmgdkabkmnadcjpehmlllkndpkmiak)

The following Safari extensions:

- [2FAS](https://apps.apple.com/fr/app/2fas-auth-browser-extension/id6443941139)
- [Obsidian Web Clipper](https://apps.apple.com/fr/app/obsidian-web-clipper/id6720708363)
- [Proton Pass](https://apps.apple.com/fr/app/proton-pass-for-safari/id6502835663)
- [uBlock Origin](https://apps.apple.com/fr/app/ublock-origin-lite/id6745342698)

Add the following bookmarks to the bookmarks bar:

- [Homelab Apps](https://apps.guillemot.me/)
- [Hacker News](https://news.ycombinator.com/news)
- [GitHub](https://github.com/)
- [Kite News](https://kite.kagi.com/)
- [Via](https://usevia.app/)
- [Archive.is](<javascript:location.href='https://archive.is/'+encodeURIComponent(document.location)>)

### Others

Install [CleanMyMac](https://macpaw.com/fr/download/cleanmymac)

Change the wallpaper using the ones from `wallpaper` directory.

Do not forget to log out and log back in to make sure all changes are applied.
