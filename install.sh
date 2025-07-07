#!/bin/bash

set -eo pipefail

# Detect OS
macos=$([ "$(uname)" = "Darwin" ] && echo true || echo false)

# Current directory
BASEDIR=$(realpath "$(dirname "$0")")

# Link a file to the target location
link_file() {
  source=$1
  target=$2

  echo "Linking $source to $target..."

  # Check if the link already exist
  if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
    return
  fi

  # If the file exists and is a sym link, remove it
  if [ -L "$target" ]; then
    rm "$target"
  fi

  # If the file exists and is not a sym link, back it up
  if [ -f "$target" ] || [ -d "$target" ]; then
    mv "$target" "$target.backup"
  fi

  # Create the link
  ln -s "$source" "$target"
}

# Install brew
if ! which brew >/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install depedencies
if $macos; then
  # Install Brewfile
  echo "Installing brew dependencies..."
  brew bundle
else
  # Install apt
  echo "Installing apt depedencies"
  xargs -a apt-list sudo apt-get install

  # Change shell to zsh
  if [[ "$SHELL" != *"zsh"* ]]; then
    chsh -s $(which zsh)
  fi

  # Load brew
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

  # Install brew depedencies
  brew bundle --file=Brewfile-linux

  # Link configs
  mkdir -p ~/.config/lazygit/
  link_file "$BASEDIR/lazygit/config.yml" ~/.config/lazygit/config.yml
  link_file "$BASEDIR/k9s" ~/.config/k9s/
fi

# Create config links
link_file "$BASEDIR/zsh/.secrets.sh" ~/.secrets.sh
link_file "$BASEDIR/zsh/.zsh_plugins.txt" ~/.zsh_plugins.txt
link_file "$BASEDIR/zsh/.zfunc" ~/.zfunc
link_file "$BASEDIR/zsh/.zshrc" ~/.zshrc
link_file "$BASEDIR/zsh/atuin/config.toml" ~/.config/atuin/config.toml
link_file "$BASEDIR/nvim" ~/.config/nvim
link_file "$BASEDIR/tmux" ~/.config/tmux
link_file "$BASEDIR/sqlfluff/.sqlfluff" ~/.sqlfluff
link_file "$BASEDIR/commitizen/.cz.toml" ~/.cz.toml
link_file "$BASEDIR/tmux/tmux-powerline" "$HOME/.config/tmux-powerline"
link_file "$BASEDIR/.tool-versions" ~/.tool-versions
link_file "$BASEDIR/asdf/.asdfrc" ~/.asdfrc
link_file "$BASEDIR/mcphub" ~/.config/mcphub

# Install tmux catpuccin
if [ ! -d ~/.config/tmux/plugins/catppuccin ]; then
  mkdir -p ~/.config/tmux/plugins/catppuccin
  git clone -b v2.1.3 https://github.com/catppuccin/tmux.git ~/.config/tmux/plugins/catppuccin/tmux
fi

# GH
if ! gh auth status >/dev/null; then
  gh auth login
fi
gh extension install github/gh-copilot

# Ensure tmux tpm is installed
if [ ! -d "$BASEDIR/tmux/plugins/tpm" ]; then
  mkdir -p "$BASEDIR/tmux/plugins"
  git clone https://github.com/tmux-plugins/tpm "$BASEDIR/tmux/plugins/tpm"
fi

# Git config
link_file "$BASEDIR/git/.gitconfig" ~/.gitconfig-global
link_file "$BASEDIR/git/.gitignore" ~/.gitignore
if ! grep -q "gitconfig-global" ~/.gitconfig; then
  echo "[include]
    path = .gitconfig-global" >>~/.gitconfig
fi

# Mac os specifics
if $macos; then
  # Config links
  link_file "$BASEDIR/lazygit/config.yml" ~/Library/Application\ Support/lazygit/config.yml
  link_file "$BASEDIR/ghostty" ~/.config/ghostty
  link_file "$BASEDIR/karabiner" ~/.config/karabiner
  link_file "$BASEDIR/hammerspoon" ~/.hammerspoon
  link_file "$BASEDIR/launchd/local.brew.upgrade.plist" ~/Library/LaunchAgents/local.brew.upgrade.plist
  link_file "$BASEDIR/k9s" "$HOME/Library/Application Support/k9s"

  # Better touch tool
  echo 'Setting up bettertouchtool...'
  killall "BetterTouchTool" >/dev/null 2>&1 || true
  link_file "$BASEDIR/bettertouchtool/library" ~/Library/Application\ Support/BetterTouchTool
  cp "$BASEDIR/bettertouchtool/com.hegenberg.BetterTouchTool.plist" ~/Library/Preferences/com.hegenberg.BetterTouchTool.plist

  # Alt tab
  echo 'Setting up alt-tab...'
  defaults import com.lwouis.alt-tab-macos "$BASEDIR/alttab/com.lwouis.alt-tab-macos.plist"

  # Macos settings
  echo 'Applying macos settings...'
  defaults write NSGlobalDomain AppleShowAllExtensions -bool true                      # Always show extensions
  defaults write com.apple.Finder AppleShowAllFiles -bool false                        # Do not show hidden files
  defaults write com.apple.terminal StringEncodings -array 4                           # Set utf8 in terminal
  defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true          # Expand save dialog
  defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true         # Expand save dialog
  defaults write NSGlobalDomain AppleKeyboardUIMode -int 3                             # Enable full keyboard access
  defaults write com.apple.finder ShowPathbar -bool true                               # Show path bar in finder
  defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true             # Expand print dialog
  defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true            # Expand print dialog
  defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false           # Disable auto capitalization
  defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false       # Disable auto correction
  defaults write NSGlobalDomain AppleFontSmoothing -int 1                              # Enable subpixel font rendering on non-Apple LCDs
  defaults write com.apple.finder ShowStatusBar -bool true                             # Show status bar
  defaults write com.apple.finder _FXShowPosixPathInTitle -bool true                   # Display full POSIX path as Finder window title
  defaults write com.apple.finder _FXSortFoldersFirst -bool true                       # Keep folders on top when sorting by name
  defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false           # Disable the warning when changing a file extension
  defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true         # Disable .DS_Store on network volumes
  defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true             # Disable .DS_Store on USB volumes
  defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"                  # Use list view in all Finder windows by default
  defaults write com.apple.finder NewWindowTarget -string "PfHm"                       # Set home as default finder location
  defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"                  # Search the current folder by default
  defaults write com.apple.dock expose-group-by-app -bool false                        # Don’t group windows by application in Mission Control
  defaults write com.apple.dock autohide-delay -float 0                                # Remove the auto-hiding Dock delay
  defaults write com.apple.dock autohide-time-modifier -float 0                        # Remove the animation when hiding/showing the Dock
  defaults write com.apple.dock autohide -bool true                                    # Automatically hide and show the Dock
  defaults write com.apple.dock show-recents -bool false                               # Don't show recent applications in Dock
  defaults write com.apple.dock no-bouncing -bool TRUE                                 # Disable bouncing in dock
  sudo defaults write com.apple.Safari AutoFillFromAddressBook -bool false             # Disable AutoFill in safari
  sudo defaults write com.apple.Safari AutoFillPasswords -bool false                   # Disable AutoFill in safari
  sudo defaults write com.apple.Safari AutoFillCreditCardData -bool false              # Disable AutoFill in safari
  sudo defaults write com.apple.Safari AutoFillMiscellaneousForms -bool false          # Disable AutoFill in safari
  sudo defaults write com.apple.Safari InstallExtensionUpdatesAutomatically -bool true # Update extensions automatically
  sudo pmset -b lowpowermode 0                                                         # Enable low power mode on battery
  defaults write -g InitialKeyRepeat -int 10                                           # Set initial key repeat to fast
  defaults write -g KeyRepeat -int 2                                                   # Set key repeat to fast
  defaults write -g NSWindowShouldDragOnGesture -bool true                             # Enable drag on gesture

  # Restart apps modified
  for app in Finder Dock SystemUIServer Safari; do killall "$app" || true; done

  # Open apps
  open_app_if_not_running() {
    if [ -z "$1" ]; then
      echo "Usage: open_app_if_not_running AppName.app"
      return 1
    fi

    app_name="$1"

    if ! pgrep -f "$app_name" >/dev/null; then
      echo "Opening $app_name..."
      open -a "$app_name"
    fi
  }

  open_app_if_not_running "BetterTouchTool"
  open_app_if_not_running "AltTab"
  open_app_if_not_running "Hammerspoon"
  open_app_if_not_running "Karabiner"
  open_app_if_not_running "Docker"
  open_app_if_not_running "AlDente"
  open_app_if_not_running "Stats"
  open_app_if_not_running "Dropshelf"
  open_app_if_not_running "CleanShot X"

  # Use TouchId for sudo
  if ! grep -q "pam_tid.so" /etc/pam.d/sudo; then
    # Create a backup of the original file
    sudo cp /etc/pam.d/sudo /etc/pam.d/sudo.bak

    # Add the line to the beginning of the file
    sudo sed -i '' '1s/^/auth optional \/opt\/homebrew\/lib\/pam\/pam_reattach.so\nauth sufficient pam_tid.so\n/' /etc/pam.d/sudo
  fi
fi

# ASDF
echo 'Setting up asdf...'
asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git
asdf plugin add golang https://github.com/asdf-community/asdf-golang.git
asdf plugin add python https://github.com/asdf-community/asdf-python.git
asdf plugin add java https://github.com/halcyon/asdf-java.git
asdf plugin update --all
asdf install

# Golang
go install golang.org/x/tools/cmd/goimports@latest

# Node
echo 'Installing node dependencies...'
npm i -g npm-check-updates neovim

# Python
echo 'Installing python dependencies...'
pipx install pylatexenc poetry
pip3 install --user --break-system-packages neovim
uv tool install vectorcode
uv tool install mcp-server-git

# Rust
rustup install stable
rustup default stable

# Ruff
uv tool install ruff@latest
