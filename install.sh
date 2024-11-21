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
link_file "$BASEDIR/zsh/.zshrc" ~/.zshrc
link_file "$BASEDIR/starship/starship.toml" ~/.config/starship.toml
link_file "$BASEDIR/alacritty/.alacritty.toml" ~/.alacritty.toml
link_file "$BASEDIR/nvim" ~/.config/nvim
link_file "$BASEDIR/tmux" ~/.config/tmux
link_file "$BASEDIR/ranger" ~/.config/ranger
link_file "$BASEDIR/lazygit/config.yml" ~/Library/Application\ Support/lazygit/config.yml

# Update Alacritty icon
"$BASEDIR/alacritty/update-alacritty-icon.sh"

# Install fonts
font_dir="$HOME/Library/Fonts"
cp "$BASEDIR"/fonts/* "$font_dir"

# Macos specifics
echo 'Applying macos settings...'
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.Finder AppleShowAllFiles -bool false
defaults write com.apple.terminal StringEncodings -array 4
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3
defaults write com.apple.finder ShowPathbar -bool true

# Restart apps modified
for app in Finder Dock SystemUIServer; do killall "$app" >/dev/null 2>&1; done

# Node
if [ ! -d "${HOME}/.nvm/.git" ]; then
  echo 'Installing nvm...'
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

  nvm install stable
  nvm use stable
  npm i -g npm-check-updates
fi

# Rust
if ! which rustc >/dev/null; then
  echo 'Installing rust...'
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
fi
