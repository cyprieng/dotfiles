# Dotfiles

My dotfiles for macOS.

Some files (claude and raycast configurations) are encrypted and can only be decrypted with my private key.
Do not use the dotfiles as-is but as a base for your configuration.

## Available Commands

Run `make help` to see all available commands:

- `make install` - Full installation (runs stow, deps, and setup)
- `make stow` - Symlink all dotfiles to your home directory
- `make unstow` - Remove all symlinks
- `make init` - Install brew and stow
- `make deps` - Install all dependencies (Homebrew, Go, Node, Python, Rust packages)
- `make setup` - Configure apps & system settings (decrypt secrets, setup git, apply macOS settings)
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
- Display Link Manager
- Hammerspoon
- Raycast
- Shortcat
- AltTab
- Karabiner
- BetterTouchTool
- Boring Notch

### Dock

Rearrange Dock:

- Zen browser
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

The following Zen extensions:

- [2FAS](https://addons.mozilla.org/fr/firefox/addon/2fas-two-factor-authentication/)
- [Web Archives](https://addons.mozilla.org/fr/firefox/addon/view-page-archive/)
- [Obsidian Web Clipper](https://addons.mozilla.org/fr/firefox/addon/web-clipper-obsidian/)
- [Old Reddit Redirect](https://addons.mozilla.org/fr/firefox/addon/old-reddit-redirect/)
- [Proton Pass](https://addons.mozilla.org/fr/firefox/addon/proton-pass/)
- [uBlock Origin](https://addons.mozilla.org/fr/firefox/addon/ublock-origin/)
- [Vimium](https://addons.mozilla.org/fr/firefox/addon/vimium-ff/)

Add the following bookmarks to the bookmarks bar:

- [Homelab Apps](https://apps.guillemot.me/)
- [Hacker News](https://news.ycombinator.com/news)
- [GitHub](https://github.com/)
- [Kite News](https://kite.kagi.com/)
- [Via](https://usevia.app/)

### Others

Install [CleanMyMac](https://macpaw.com/fr/download/cleanmymac)

Change the wallpaper using the ones from `wallpaper` directory.

Do not forget to log out and log back in to make sure all changes are applied.
