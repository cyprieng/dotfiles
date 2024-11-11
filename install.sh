#!/bin/bash

set -eo pipefail

# Current directory
BASEDIR=$(realpath $(dirname $0))

# Install a brew package if not installed
install_brew_package() {
    package=$1
    echo "Installing $package..."
    brew list $package > /dev/null 2>&1 || brew install $package
}

# Link a file to the target location
link_file() {
    source=$1
    target=$2

    echo "Linking $source to $target..."

    # Check if the link already exist
    if [ -L $target ] && [ "$(readlink $target)" = $source ]; then
        return
    fi

    # If the file exists, back it up and remove it
    if [ -f $target ] ; then
        mv $target $target.backup
    fi

    # Create the link
    ln -s $source $target
}

# Install alacritty
echo "Installing alacritty..."
brew list alacritty > /dev/null 2>&1 || brew install --cask alacritty --no-quarantine

# Install neovim
install_brew_package neovim

# Install other packages
install_brew_package ripgrep
install_brew_package ast-grep
install_brew_package luarocks
install_brew_package lazygit
install_brew_package fd

# Create links
link_file "$BASEDIR/.alacritty.toml" ~/.alacritty.toml
link_file "$BASEDIR/nvim" ~/.config/nvim
link_file "$BASEDIR/.zsh_extend.sh" ~/.zsh_extend.sh

# Update Alacritty icon
"$BASEDIR/update-alacritty-icon.sh"

# Install oh-my-zsh
if [ ! "$(grep oh-my-zsh ~/.zshrc)" ]; then
    echo "Installing oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Install zsh_extend.sh
if [ ! "$(grep zsh_extend.sh ~/.zshrc)" ]; then
    echo "Installing zsh_extend.sh..."
    echo "source ~/.zsh_extend.sh" >> ~/.zshrc
fi

# Install fonts
font_dir="$HOME/Library/Fonts"
cp $BASEDIR/assets/fonts/* "$font_dir"
