UNAME := $(shell uname)
PATH  := /opt/homebrew/bin:/home/linuxbrew/.linuxbrew/bin:$(PATH)
SHELL := env PATH=$(PATH) /bin/bash
.PHONY: help install install-macos install-linux \
        stow stow-macos stow-linux unstow unstow-macos unstow-linux \
        init init-macos init-linux deps deps-macos deps-linux \
        setup setup-common setup-macos setup-linux tools \
        update clean backup extra

PACKAGES_MACOS := aerospace bettertouchtool claude commitizen ghostty git gnupg hammerspoon k9s karabiner lazygit nvim sqlfluff tmux zsh mise
PACKAGES_LINUX := zsh nvim tmux git lazygit k9s mise sqlfluff commitizen ghostty claude i3 polybar picom rofi

help:
	@echo "Available commands:"
	@echo "  make install        - Full installation (auto-detects OS)"
	@echo "  make install-macos  - macOS full installation"
	@echo "  make install-linux  - Linux full installation"
	@echo "  make stow           - Symlink dotfiles (auto-detects OS)"
	@echo "  make unstow         - Remove symlinks (auto-detects OS)"
	@echo "  make init           - Install prerequisites (auto-detects OS)"
	@echo "  make deps           - Install dependencies (auto-detects OS)"
	@echo "  make setup          - Configure system (auto-detects OS)"
	@echo "  make tools          - Install language tools via mise + uv (after stow)"
	@echo "  make update         - Update everything"
	@echo "  make clean          - Clean up broken symlinks"
	@echo "  make backup         - Backup app configurations (macOS)"

# ==============================================================================
# Dispatchers
# ==============================================================================

install:
ifeq ($(UNAME), Darwin)
	$(MAKE) install-macos
else
	$(MAKE) install-linux
endif

stow:
ifeq ($(UNAME), Darwin)
	$(MAKE) stow-macos
else
	$(MAKE) stow-linux
endif

unstow:
ifeq ($(UNAME), Darwin)
	$(MAKE) unstow-macos
else
	$(MAKE) unstow-linux
endif

init:
ifeq ($(UNAME), Darwin)
	$(MAKE) init-macos
else
	$(MAKE) init-linux
endif

deps:
ifeq ($(UNAME), Darwin)
	$(MAKE) deps-macos
else
	$(MAKE) deps-linux
endif

setup:
ifeq ($(UNAME), Darwin)
	$(MAKE) setup-macos
else
	$(MAKE) setup-linux
endif

# ==============================================================================
# Main installation
# ==============================================================================

install-macos: init-macos stow-macos deps-macos setup-macos tools
	@echo "✓ macOS installation complete!"

install-linux: init-linux deps-linux stow-linux setup-linux tools
	@echo "✓ Linux installation complete!"

# ==============================================================================
# Symlink management
# ==============================================================================

stow-macos:
	@echo "Symlinking dotfiles (macOS)..."
	@stow --dotfiles --ignore='\.DS_Store' -t $(HOME) $(PACKAGES_MACOS)

stow-linux:
	@echo "Symlinking dotfiles (Linux)..."
	@stow --dotfiles --ignore='\.DS_Store' --ignore='Library' -t $(HOME) $(PACKAGES_LINUX)

unstow-macos:
	@echo "Removing symlinks (macOS)..."
	@stow -D --dotfiles --ignore='\.DS_Store' -t $(HOME) $(PACKAGES_MACOS)

unstow-linux:
	@echo "Removing symlinks (Linux)..."
	@stow -D --dotfiles --ignore='\.DS_Store' --ignore='Library' -t $(HOME) $(PACKAGES_LINUX)

# ==============================================================================
# Dependencies installation
# ==============================================================================

init-macos:
	# Install brew
	@echo "Installing Homebrew..."
	@which brew >/dev/null || /bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

	# Install stow
	@brew install stow

init-linux:
	@echo "Installing prerequisites via apt..."
	@sudo apt-get update -qq
	@sudo apt-get install -y curl build-essential

deps-macos:
	# Install Brewfile
	@echo "Installing brew dependencies..."
	@brew bundle

deps-linux:
	@echo "Installing apt packages..."
	@sudo apt-get update -qq
	@grep -v '^#\|^$$' apt-packages.txt | xargs sudo apt-get install -y

	@echo "Installing Homebrew (Linux)..."
	@which brew >/dev/null || /bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

	@echo "Installing brew packages (Linux)..."
	@brew bundle --file=Brewfile-linux

	@echo "Installing JetBrains Mono Nerd Font..."
	@mkdir -p ~/.local/share/fonts
	@wget -O /tmp/JetBrainsMono.zip https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
	@unzip -o /tmp/JetBrainsMono.zip -d ~/.local/share/fonts/JetBrainsMono > /dev/null
	@fc-cache -f ~/.local/share/fonts
	@rm /tmp/JetBrainsMono.zip

	@echo "Installing Google Chrome..."
	@curl -L -o /tmp/chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
	@sudo apt-get install -y /tmp/chrome.deb
	@rm /tmp/chrome.deb

	@echo "Installing Ghostty..."
	@/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/mkasberg/ghostty-ubuntu/HEAD/install.sh)"

	@echo "Installing Obsidian..."
	@OBSIDIAN_URL=$$(curl -s https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest | grep -o 'https://[^"]*amd64\.deb' | head -1); \
		curl -L -o /tmp/obsidian.deb "$$OBSIDIAN_URL"; \
		sudo apt-get install -y /tmp/obsidian.deb; \
		rm /tmp/obsidian.deb

	@echo "Installing Postman..."
	@curl -L https://dl.pstmn.io/download/latest/linux64 -o /tmp/postman.tar.gz
	@sudo tar -xzf /tmp/postman.tar.gz -C /opt
	@sudo ln -sf /opt/Postman/Postman /usr/local/bin/postman
	@ICON=$$(find /opt/Postman -name "icon.png" | head -1); \
		printf '[Desktop Entry]\nName=Postman\nExec=/opt/Postman/Postman\nIcon=%s\nTerminal=false\nType=Application\nCategories=Development;\n' "$$ICON" \
		| sudo tee /usr/share/applications/postman.desktop > /dev/null
	@rm /tmp/postman.tar.gz

	@echo "Installing RustDesk..."
	@RUSTDESK_URL=$$(curl -s https://api.github.com/repos/rustdesk/rustdesk/releases/latest | grep -o 'https://[^"]*x86_64\.deb' | head -1); \
		wget -O /tmp/rustdesk.deb "$$RUSTDESK_URL"; \
		sudo apt-get install -y /tmp/rustdesk.deb; \
		rm /tmp/rustdesk.deb

# ==============================================================================
# Language tools (shared, requires dotfiles to be stowed first)
# ==============================================================================

tools:
	@echo "Installing language tools..."
	@mise install
	@uv tool install "markitdown[all]"

	@echo "Installing Claude Code..."
	@curl -fsSL https://claude.ai/install.sh | bash

# ==============================================================================
# System and app configuration
# ==============================================================================

setup-common:
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
	@grep -q "gitconfig-global" ~/.gitconfig 2>/dev/null || printf "[include]\n    path = .gitconfig-global\n" >> ~/.gitconfig

	# GPG key
	@if [ -z "$$(git config --global user.signingkey)" ]; then \
		echo ""; \
		echo "=== GPG Key Setup ==="; \
		if ! gpg --list-secret-keys --keyid-format=long 2>/dev/null | grep -q "sec"; then \
			echo "No GPG keys found."; \
			echo ""; \
			read -p "Do you want to generate a new GPG key? (Y/n): " generate; \
			if [ "$$generate" != "n" ] && [ "$$generate" != "N" ]; then \
				echo ""; \
				echo "Generating new GPG key (interactive)..."; \
				gpg --full-generate-key; \
				echo ""; \
				echo "✓ GPG key generated successfully!"; \
				echo ""; \
				echo "⚠️  Don't forget to add your GPG key to GitHub:"; \
				echo "   1. Export your public key: gpg --armor --export <KEY_ID>"; \
				echo "   2. Go to: https://github.com/settings/keys"; \
				echo "   3. Click 'New GPG key' and paste your public key"; \
				echo ""; \
			else \
				echo ""; \
				echo "Skipped. Import your existing key with:"; \
				echo "  gpg --import /path/to/your/private-key.asc"; \
				echo ""; \
				echo "Then run 'make setup' again."; \
				exit 0; \
			fi; \
		fi; \
		echo ""; \
		echo "=== Available GPG Secret Keys ==="; \
		gpg --list-secret-keys --keyid-format=long; \
		echo ""; \
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

setup-macos: setup-common
	# Better touch tool
	# The plist cannot be a symlink, so we need to copy it
	@echo "Setting up BetterTouchTool..."
	@killall "BetterTouchTool" >/dev/null 2>&1 || true
	@cp bettertouchtool/Library/Preferences/com.hegenberg.BetterTouchTool.plist ~/Library/Preferences/com.hegenberg.BetterTouchTool.plist

	# Reload gpg-agent so pinentry-mac config takes effect
	@echo "Reloading gpg-agent..."
	@gpg-connect-agent reloadagent /bye >/dev/null 2>&1 || true

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
	@defaults write -g InitialKeyRepeat -int 10                                           # Set initial key repeat to fast
	@defaults write -g KeyRepeat -int 2                                                   # Set key repeat to fast
	@defaults write -g NSWindowShouldDragOnGesture -bool true                             # Enable drag on gesture
	@defaults write com.apple.dock expose-group-apps -bool true                           # Fix mission control for aerospace
	@defaults write com.apple.spaces spans-displays -bool false                           # Enable separate spaces for displays
	@launchctl unload -w /System/Library/LaunchAgents/com.apple.rcd.plist 2>/dev/null || true # Disable Apple Music opening on media key press
	@defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false # Fix scroll direction
	@defaults write com.apple.dock minimize-to-application -bool true # Minimize into app icon

	# Reduce dock animation time
	@defaults write com.apple.dock mineffect -string "scale"
	@defaults write com.apple.dock mineffect-duration -float 0.1

	# Raycast
	@echo "Setting up Raycast..."
	@echo "Decrypting Raycast configuration..."
	@gpg --decrypt -o raycast/config.rayconfig raycast/config.rayconfig.gpg 2>/dev/null || echo "⚠️  Warning: Could not decrypt Raycast config (wrong password or file missing)"
	@open raycast/config.rayconfig

setup-linux: setup-common
	# Set zsh as default shell
	@if [ "$$SHELL" != "$$(which zsh)" ]; then \
		echo "Setting zsh as default shell..."; \
		chsh -s $$(which zsh); \
	fi

	# SDDM auto-login
	@echo "Configuring SDDM auto-login..."
	@sudo mkdir -p /etc/sddm.conf.d
	@printf '[Autologin]\nUser=cyprien\nSession=i3\n' | sudo tee /etc/sddm.conf.d/autologin.conf > /dev/null
	@sudo systemctl enable sddm

	# GPG loopback (no pinentry, passphrase asked inline in terminal)
	@mkdir -p ~/.gnupg && chmod 700 ~/.gnupg
	@printf 'pinentry-mode loopback\n' > ~/.gnupg/gpg.conf
	@printf 'allow-loopback-pinentry\ndefault-cache-ttl 86400\nmax-cache-ttl 86400\n' > ~/.gnupg/gpg-agent.conf
	@chmod 600 ~/.gnupg/gpg.conf ~/.gnupg/gpg-agent.conf
	@gpg-connect-agent reloadagent /bye >/dev/null 2>&1 || true

# ==============================================================================
# Extra setup (macOS only)
# ==============================================================================
extra:
	@echo "Installing extra brew dependencies..."
	@brew bundle --file=Brewfile-extra

	# Use TouchId for sudo
	@echo "Setting up TouchID for sudo..."
	@grep -q "pam_tid.so" /etc/pam.d/sudo 2>/dev/null || (sudo cp /etc/pam.d/sudo /etc/pam.d/sudo.bak && sudo sed -i '' '1s/^/auth optional \/opt\/homebrew\/lib\/pam\/pam_reattach.so\nauth sufficient pam_tid.so\n/' /etc/pam.d/sudo)


# ==============================================================================
# Update
# ==============================================================================

update:
	@echo "Updating Homebrew..."
	@brew update && brew upgrade && brew cleanup

	@echo "Updating Zinit..."
	@zsh -ic 'zinit self-update'
	@zsh -ic 'zinit update'

	@echo "Updating mise..."
	@mise upgrade

# ==============================================================================
# Cleanup
# ==============================================================================

clean:
	@echo "Cleaning up brew formulae and casks"
ifeq ($(UNAME), Darwin)
	@./clean-brew.sh
endif

	@echo "Cleaning up broken symlinks..."
	@find ~ -maxdepth 1 -type l ! -exec test -e {} \; -print -delete 2>/dev/null || true
	@find ~/.config -maxdepth 2 -type l ! -exec test -e {} \; -print -delete 2>/dev/null || true
ifeq ($(UNAME), Darwin)
	@find ~/Library/Application\ Support -maxdepth 2 -type l ! -exec test -e {} \; -print -delete 2>/dev/null || true
endif

	@echo "Cleaning Homebrew..."
	@brew cleanup

ifeq ($(UNAME), Darwin)
	@echo "Cleaning system..."
	@mo clean
endif

# ==============================================================================
# Backup for configuration that cannot be symlinked (macOS only)
# ==============================================================================

backup:
	@echo "Backing up BetterTouchTool configuration..."
	@./bettertouchtool/backup_config.sh

	@echo "Backing up Raycast configuration..."
	@./raycast/backup_config.sh
