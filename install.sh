#!/bin/bash

set -eo pipefail

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
  if [ -f "$target" ]; then
    mv "$target" "$target.backup"
  fi

  # Create the link
  ln -s "$source" "$target"
}

# Install starship
if ! which starship >/dev/null; then
  curl -sS https://starship.rs/install.sh | sh
fi

# Install Brewfile
echo "Installing brew dependencies..."
brew bundle

# Open Rectangle
echo 'Setting up rectangle...'
killall "Rectangle" >/dev/null 2>&1 || true
mkdir -p ~/Library/Application\ Support/Rectangle
cp rectangle/RectangleConfig.json ~/Library/Application\ Support/Rectangle/RectangleConfig.json
open -n /Applications/Rectangle.app

# Create links
link_file "$BASEDIR/zsh/.secrets.sh" ~/.secrets.sh
link_file "$BASEDIR/zsh/.zshrc" ~/.zshrc
link_file "$BASEDIR/starship/starship.toml" ~/.config/starship.toml
link_file "$BASEDIR/alacritty/.alacritty.toml" ~/.alacritty.toml
link_file "$BASEDIR/nvim" ~/.config/nvim
link_file "$BASEDIR/tmux" ~/.config/tmux
link_file "$BASEDIR/ranger" ~/.config/ranger
link_file "$BASEDIR/vale" ~/.config/vale
link_file "$BASEDIR/aider/.aider.conf.yml" ~/.aider.conf.yml
link_file "$BASEDIR/lazygit/config.yml" ~/Library/Application\ Support/lazygit/config.yml
link_file "$BASEDIR/sqlfluff/.sqlfluff" ~/.sqlfluff
link_file "$BASEDIR/karabiner" ~/.config/karabiner
link_file "$BASEDIR/commitizen/.cz.toml" ~/.cz.toml

# Git config
link_file "$BASEDIR/git/.gitconfig" ~/.gitconfig-global
link_file "$BASEDIR/git/.gitignore" ~/.gitignore
if ! grep -q "gitconfig-global" ~/.gitconfig; then
  echo "[include]
    path = .gitconfig-global" >>~/.gitconfig
fi

# Vale
(cd ~/.config/vale && vale sync)

# Weather
go install git.sr.ht/~timharek/yr@latest

# Update Alacritty icon
"$BASEDIR/alacritty/update-alacritty-icon.sh"

# Install fonts
font_dir="$HOME/Library/Fonts"
cp "$BASEDIR"/fonts/* "$font_dir"

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

# Restart apps modified
for app in Finder Dock SystemUIServer Safari; do killall "$app" || true; done

# Node
if [ ! -d "${HOME}/.nvm/.git" ]; then
  echo 'Installing nvm...'
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

  nvm install stable
  nvm use stable
fi
echo 'Installing node dependencies...'
npm i -g npm-check-updates neovim

# Rust
if ! which rustc >/dev/null; then
  echo 'Installing rust...'
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
fi

# Python
echo 'Installing python dependencies...'
pipx install pylatexenc
pip3 install --user --break-system-packages neovim
