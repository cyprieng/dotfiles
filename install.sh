#!/bin/bash

set -eo pipefail

# Current directory
BASEDIR=$(realpath "$(dirname "$0")")

# Install brew
if ! which brew >/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install Brewfile
echo "Installing brew dependencies..."
brew bundle

# Decrypt secrets
git secret reveal -f

# Better touch tool
# The plist cannot be a symlink, so we need to copy it
echo 'Setting up bettertouchtool...'
killall "BetterTouchTool" >/dev/null 2>&1 || true
cp "$BASEDIR/bettertouchtool/Library/Preferences/com.hegenberg.BetterTouchTool.plist" ~/Library/Preferences/com.hegenberg.BetterTouchTool.plist

# Link configs
stow --dotfiles --ignore='\.DS_Store' -t $HOME aerospace bettertouchtool claude commitizen ghostty git hammerspoon k9s karabiner lazygit nvim sqlfluff tmux zsh

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
if [ ! -d ~/.config/tmux/plugins/tpm ]; then
  mkdir -p ~/.config/tmux/plugins
  git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
fi

# Git config
if ! grep -q "gitconfig-global" ~/.gitconfig; then
  echo "[include]
    path = .gitconfig-global" >>~/.gitconfig
fi

# Link docker cli plugins because we use colima
ln -sfn $(which docker-buildx) ~/.docker/cli-plugins
ln -sfn $(which docker-compose) ~/.docker/cli-plugins

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
sudo pmset -b lowpowermode 0                                                         # No low power mode on battery
defaults write -g InitialKeyRepeat -int 10                                           # Set initial key repeat to fast
defaults write -g KeyRepeat -int 2                                                   # Set key repeat to fast
defaults write -g NSWindowShouldDragOnGesture -bool true                             # Enable drag on gesture
defaults write com.apple.dock expose-group-apps -bool true                           # Fix mission control for aerospace
defaults write com.apple.spaces spans-displays -bool false                           # Enable separate spaces for displays
sudo defaults write com.apple.universalaccess reduceMotion -bool true                # Reduce motion
launchctl unload -w /System/Library/LaunchAgents/com.apple.rcd.plist                 # Disable Apple Music opening on media key press
defaults write com.apple.dock launchanim -bool false                                 # Disable launch animation

# Reduce dock animation time
defaults write com.apple.dock mineffect -string "scale"
defaults write com.apple.dock mineffect-duration -float 0.1

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
open_app_if_not_running "AlDente"
open_app_if_not_running "CleanShot X"

# Use TouchId for sudo
if ! grep -q "pam_tid.so" /etc/pam.d/sudo; then
  # Create a backup of the original file
  sudo cp /etc/pam.d/sudo /etc/pam.d/sudo.bak

  # Add the line to the beginning of the file
  sudo sed -i '' '1s/^/auth optional \/opt\/homebrew\/lib\/pam\/pam_reattach.so\nauth sufficient pam_tid.so\n/' /etc/pam.d/sudo
fi

# Golang
go install golang.org/x/tools/cmd/goimports@latest

# Node
echo 'Installing node dependencies...'
npm i -g npm-check-updates neovim

# Claude code
/opt/homebrew/bin/npm install -g @anthropic-ai/claude-code
/opt/homebrew/bin/claude mcp add-from-claude-desktop --scope user

# Python
echo 'Installing python dependencies...'
pipx install pylatexenc poetry
pip3 install --user --break-system-packages neovim
uv tool install mcp-server-git
uv tool install 'markitdown[all]'
uv tool install markitdown-mcp

# Rust
rustup install stable
rustup default stable

# Ruff
uv tool install ruff@latest
