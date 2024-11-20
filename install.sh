#!/bin/bash

set -eo pipefail

# Current directory
BASEDIR=$(realpath "$(dirname "$0")")

# Install a brew package if not installed
install_brew_package() {
  package=$1
  echo "Installing $package..."
  brew list "$package" >/dev/null 2>&1 || brew install "$package"
}

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

# Install alacritty
echo "Installing alacritty..."
brew list alacritty >/dev/null 2>&1 || brew install --cask alacritty --no-quarantine

# Install neovim
install_brew_package neovim

# Install other packages
install_brew_package antidote
install_brew_package ripgrep
install_brew_package ast-grep
install_brew_package luarocks
install_brew_package lazygit
install_brew_package fd
install_brew_package git-delta
install_brew_package fzf
install_brew_package tmux
install_brew_package bat
install_brew_package fpp
install_brew_package jq

# Create links
link_file "$BASEDIR/zsh/.zshrc" ~/.zshrc
link_file "$BASEDIR/starship/starship.toml" ~/.config/starship.toml
link_file "$BASEDIR/alacritty/.alacritty.toml" ~/.alacritty.toml
link_file "$BASEDIR/nvim" ~/.config/nvim
link_file "$BASEDIR/tmux" ~/.config/tmux
link_file "$BASEDIR/lazygit/config.yml" ~/Library/Application\ Support/lazygit/config.yml

# Update Alacritty icon
"$BASEDIR/alacritty/update-alacritty-icon.sh"

# Install fonts
font_dir="$HOME/Library/Fonts"
cp "$BASEDIR"/fonts/* "$font_dir"

# Node
if [ ! -d "${HOME}/.nvm/.git" ]; then
  echo 'Installing nvm...'
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

  nvm install stable
  nvm use stable
fi

# Golang
install_brew_package go
