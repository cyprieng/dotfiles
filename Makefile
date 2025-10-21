PATH  := $(PATH):/opt/homebrew/bin/
SHELL := env PATH=$(PATH) /bin/bash
.PHONY: help install stow unstow init deps setup update clean backup

help:
	@echo "Available commands:"
	@echo "  make install  - Full installation (everything)"
	@echo "  make stow     - Symlink all dotfiles"
	@echo "  make unstow   - Remove all symlinks"
	@echo "  make init     - Install brew and stow"
	@echo "  make deps     - Install all dependencies (brew + languages)"
	@echo "  make setup    - Configure apps & system settings"
	@echo "  make update   - Update everything"
	@echo "  make clean    - Clean up broken symlinks"
	@echo "  make backup   - Backup app configurations"

# ==============================================================================
# Main installation
# ==============================================================================

install: init stow deps setup
	@echo "✓ Installation complete!"

# ==============================================================================
# Symlink management
# ==============================================================================

stow:
	@echo "Symlinking dotfiles..."
	@stow --dotfiles --ignore='\.DS_Store' -t $(HOME) aerospace bettertouchtool claude commitizen ghostty git hammerspoon k9s karabiner lazygit nvim sqlfluff tmux zsh

unstow:
	@echo "Removing symlinks..."
	@stow -D --dotfiles --ignore='\.DS_Store' -t $(HOME) aerospace bettertouchtool claude commitizen ghostty git hammerspoon k9s karabiner lazygit nvim sqlfluff tmux zsh

# ==============================================================================
# Dependencies installation
# ==============================================================================

init:
	# Install brew
	@echo "Installing Homebrew..."
	@which brew >/dev/null || /bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	
	# Install stow
	@brew install stow

deps:
	# Install Brewfile
	@echo "Installing brew dependencies..."
	@brew bundle

	# Golang
	@echo "Installing Go dependencies..."
	@go install golang.org/x/tools/cmd/goimports@latest

	# Node
	@echo "Installing Node dependencies..."
	@/opt/homebrew/bin/npm install -g @anthropic-ai/claude-code npm-check-updates neovim @devcontainers/cli

	# Python
	@echo "Installing Python dependencies..."
	@uv tool install pylatexenc --python 3.13
	@uv tool install poetry --python 3.13
	@uv tool install pynvim --python 3.13
	@uv tool install ruff@latest --python 3.13
	@uv tool install xmlformatter --python 3.13

	# Rust
	@echo "Installing Rust..."
	@rustup install stable
	@rustup default stable

# ==============================================================================
# System and app configuration
# ==============================================================================

setup:
	# Decrypt secrets
	@echo "Decrypting secrets..."
	@if ! git secret reveal -f; then \
		echo ""; \
		echo "❌ Error: Failed to reveal secrets"; \
		echo ""; \
		echo "This usually means your GPG key is not imported."; \
		echo ""; \
		echo "To fix this:"; \
		echo "     gpg --import /path/to/your/private-key.asc"; \
		read -p "Have you imported your GPG key? (y/N): " answer; \
		if [ "$$answer" = "y" ] || [ "$$answer" = "Y" ]; then \
			echo ""; \
			echo "Retrying..."; \
			git secret reveal -f; \
		else \
			echo "Aborted. Please import your key and run this command again."; \
			exit 1; \
		fi \
	fi

	# Better touch tool
	# The plist cannot be a symlink, so we need to copy it
	@echo "Setting up BetterTouchTool..."
	@killall "BetterTouchTool" >/dev/null 2>&1 || true
	@cp bettertouchtool/Library/Preferences/com.hegenberg.BetterTouchTool.plist ~/Library/Preferences/com.hegenberg.BetterTouchTool.plist

	# Install tmux catpuccin
	@echo "Installing tmux plugins..."
	@[ -d ~/.config/tmux/plugins/catppuccin ] || (mkdir -p ~/.config/tmux/plugins/catppuccin && git clone -b v2.1.3 https://github.com/catppuccin/tmux.git ~/.config/tmux/plugins/catppuccin/tmux)

	# Ensure tmux tpm is installed
	@[ -d ~/.config/tmux/plugins/tpm ] || (mkdir -p ~/.config/tmux/plugins && git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm)

	# GH
	@echo "Setting up GitHub..."
	@gh auth status >/dev/null 2>&1 || gh auth login
	@gh extension install github/gh-copilot 2>/dev/null || true

	# Git config
	@echo "Configuring git..."
	@grep -q "gitconfig-global" ~/.gitconfig 2>/dev/null || echo -e "[include]\n    path = .gitconfig-global" >> ~/.gitconfig

	# GPG key
	@if [ -z "$$(git config --global user.signingkey)" ]; then \
		echo "=== Available GPG Secret Keys ==="; \
		gpg --list-secret-keys --keyid-format=long; \
		read -p "Enter the key ID you want to use for Git signing: " key_id; \
		if [ -z "$$key_id" ]; then \
			echo "Error: No key ID provided."; \
			exit 1; \
		fi; \
		git config --global user.signingkey "$$key_id"; \
		echo "✓ Git signing key configured successfully!"; \
	fi

        # Git user name and email
	@if [ -z "$$(git config --global user.email)" ]; then \
		read -p "Enter your Git email: " user_email; \
		if [ -z "$$user_email" ]; then \
			echo "Error: No email provided."; \
			exit 1; \
		fi; \
		git config --global user.email "$$user_email"; \
		echo "✓ Git email configured: $$user_email"; \
	fi
	@if [ -z "$$(git config --global user.name)" ]; then \
		read -p "Enter your Git name: " user_name; \
		if [ -z "$$user_name" ]; then \
			echo "Error: No name provided."; \
			exit 1; \
		fi; \
		git config --global user.name "$$user_name"; \
		echo "✓ Git name configured: $$user_name"; \
	fi
	
	# Alt tab
	@echo "Setting up AltTab..."
	@defaults import com.lwouis.alt-tab-macos alttab/com.lwouis.alt-tab-macos.plist

	# Macos settings
	@echo "Applying macOS settings..."
	@defaults write NSGlobalDomain AppleShowAllExtensions -bool true                      # Always show extensions
	@defaults write com.apple.Finder AppleShowAllFiles -bool false                        # Do not show hidden files
	@defaults write com.apple.terminal StringEncodings -array 4                           # Set utf8 in terminal
	@defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true          # Expand save dialog
	@defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true         # Expand save dialog
	@defaults write NSGlobalDomain AppleKeyboardUIMode -int 3                             # Enable full keyboard access
	@defaults write com.apple.finder ShowPathbar -bool true                               # Show path bar in finder
	@defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true             # Expand print dialog
	@defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true            # Expand print dialog
	@defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false           # Disable auto capitalization
	@defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false       # Disable auto correction
	@defaults write NSGlobalDomain AppleFontSmoothing -int 1                              # Enable subpixel font rendering on non-Apple LCDs
	@defaults write com.apple.finder ShowStatusBar -bool true                             # Show status bar
	@defaults write com.apple.finder _FXShowPosixPathInTitle -bool true                   # Display full POSIX path as Finder window title
	@defaults write com.apple.finder _FXSortFoldersFirst -bool true                       # Keep folders on top when sorting by name
	@defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false           # Disable the warning when changing a file extension
	@defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true         # Disable .DS_Store on network volumes
	@defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true             # Disable .DS_Store on USB volumes
	@defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"                  # Use list view in all Finder windows by default
	@defaults write com.apple.finder NewWindowTarget -string "PfHm"                       # Set home as default finder location
	@defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"                  # Search the current folder by default
	@defaults write com.apple.dock expose-group-by-app -bool false                        # Don't group windows by application in Mission Control
	@defaults write com.apple.dock autohide-delay -float 0                                # Remove the auto-hiding Dock delay
	@defaults write com.apple.dock autohide-time-modifier -float 0                        # Remove the animation when hiding/showing the Dock
	@defaults write com.apple.dock autohide -bool true                                    # Automatically hide and show the Dock
	@defaults write com.apple.dock show-recents -bool false                               # Don't show recent applications in Dock
	@defaults write com.apple.dock no-bouncing -bool TRUE                                 # Disable bouncing in dock
	@sudo defaults write com.apple.Safari AutoFillFromAddressBook -bool false             # Disable AutoFill in safari
	@sudo defaults write com.apple.Safari AutoFillPasswords -bool false                   # Disable AutoFill in safari
	@sudo defaults write com.apple.Safari AutoFillCreditCardData -bool false              # Disable AutoFill in safari
	@sudo defaults write com.apple.Safari AutoFillMiscellaneousForms -bool false          # Disable AutoFill in safari
	@sudo defaults write com.apple.Safari InstallExtensionUpdatesAutomatically -bool true # Update extensions automatically
	@sudo pmset -b lowpowermode 0                                                         # No low power mode on battery
	@defaults write -g InitialKeyRepeat -int 10                                           # Set initial key repeat to fast
	@defaults write -g KeyRepeat -int 2                                                   # Set key repeat to fast
	@defaults write -g NSWindowShouldDragOnGesture -bool true                             # Enable drag on gesture
	@defaults write com.apple.dock expose-group-apps -bool true                           # Fix mission control for aerospace
	@defaults write com.apple.spaces spans-displays -bool false                           # Enable separate spaces for displays
	@launchctl unload -w /System/Library/LaunchAgents/com.apple.rcd.plist 2>/dev/null || true # Disable Apple Music opening on media key press
	@defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false # Fix scroll direction
	@defaults write com.apple.dock minimize-to-application -bool true # Minimize into app icon
	
	# Reduce animations
	@defaults write com.apple.Accessibility reduceMotion -bool true
	@defaults write com.apple.dock launchanim -bool false

	# Reduce dock animation time
	@defaults write com.apple.dock mineffect -string "scale"
	@defaults write com.apple.dock mineffect-duration -float 0.1

	# Restart apps modified
	@echo "Restarting modified apps..."
	@for app in Finder Dock SystemUIServer Safari; do killall "$$app" 2>/dev/null || true; done

	# Use TouchId for sudo
	@echo "Setting up TouchID for sudo..."
	@grep -q "pam_tid.so" /etc/pam.d/sudo 2>/dev/null || (sudo cp /etc/pam.d/sudo /etc/pam.d/sudo.bak && sudo sed -i '' '1s/^/auth optional \/opt\/homebrew\/lib\/pam\/pam_reattach.so\nauth sufficient pam_tid.so\n/' /etc/pam.d/sudo)

	# Raycast
	@echo "Setting up Raycast..."
	@open raycast/config.rayconfig

# ==============================================================================
# Update
# ==============================================================================

update:
	@echo "Updating Homebrew..."
	@brew update && brew upgrade && brew cleanup

	@echo "Updating Node packages..."
	@npm update -g

	@echo "Updating Python tools..."
	@uv tool upgrade --all

	@echo "Updating Rust..."
	@rustup update

# ==============================================================================
# Cleanup
# ==============================================================================

clean:
	@echo "Cleaning up broken symlinks..."
	@find ~ -maxdepth 1 -type l ! -exec test -e {} \; -print -delete 2>/dev/null || true
	@find ~/.config -maxdepth 2 -type l ! -exec test -e {} \; -print -delete 2>/dev/null || true
	@find ~/Library/Application\ Support -maxdepth 2 -type l ! -exec test -e {} \; -print -delete 2>/dev/null || true

	@echo "Cleaning Homebrew..."
	@brew cleanup

	@echo "Cleaning system..."
	@mo clean

# ==============================================================================
# Backup for configuration that cannot be symlinked
# ==============================================================================

backup:
	@echo "Backing up AltTab configuration..."
	@./alttab/backup_config.sh

	@echo "Backing up BetterTouchTool configuration..."
	@./bettertouchtool/backup_config.sh

	@echo "Backing up Raycast configuration..."
	@./raycast/backup_config.sh
	
	@git secret hide
