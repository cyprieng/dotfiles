#!/bin/bash

# Current directory
BASEDIR=$(realpath $(dirname $0))

# Cleanup
rm -f ~/.alacritty.toml
rm -rf ~/.config/nvim
rm -f ~/.zsh_extend.sh

# Create links
ln -s "$BASEDIR/.alacritty.toml" ~/.alacritty.toml
ln -s "$BASEDIR/nvim" ~/.config/nvim
ln -s "$BASEDIR/.zsh_extend.sh" ~/.zsh_extend.sh
