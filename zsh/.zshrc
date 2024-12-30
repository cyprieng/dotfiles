# Global configuration
export VISUAL="nvim"
export EDITOR="$VISUAL"
export GPG_TTY=$(tty)
export PATH="$HOME/.local/bin:/opt/homebrew/opt/libpq/bin:$PATH"

# Load secrets
source ~/.secrets.sh 

# Enable correction
ENABLE_CORRECTION="true"

# Load antidote
source /opt/homebrew/opt/antidote/share/antidote/antidote.zsh
antidote load

# Custom title
DISABLE_AUTO_TITLE="true"
preexec() {
  local action="$1"
  echo -ne "\033]0;$action - ${PWD##*/}\a"
}

# Aliases
export DOTFILES_DIRECTORY="$(dirname $(dirname $(readlink ~/.zshrc)))"
alias dotfiles="cd $DOTFILES_DIRECTORY && nvim"
alias v="nvim" 
alias jsoncb="pbpaste | fx"
alias weather="~/go/bin/yr today montpellier"
eval $(thefuck --alias)
alias ls="eza --icons=always --group-directories-first --git"
alias lla="ls -la"
alias vale="vale --config ~/.config/vale/.vale.ini"
alias readme-generator="npx readme-md-generator"
alias cz="cz --config ~/.cz.toml"
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

# Bind keys
bindkey "^[[1;3C" forward-word    # Alt + →
bindkey "^[[1;3D" backward-word   # Alt + ←
bindkey "^[e" redo

# Load the theme
eval "$(starship init zsh)"

# Load zoxide
eval "$(zoxide init zsh --cmd cd)"

# Load asdf
source $(brew --prefix asdf)/libexec/asdf.sh

# FZF theme
export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS \
  --highlight-line \
  --info=inline-right \
  --ansi \
  --layout=reverse \
  --border=none \
  --color=bg+:#2d3f76 \
  --color=bg:#1e2030 \
  --color=border:#589ed7 \
  --color=fg:#c8d3f5 \
  --color=gutter:#1e2030 \
  --color=header:#ff966c \
  --color=hl+:#65bcff \
  --color=hl:#65bcff \
  --color=info:#545c7e \
  --color=marker:#ff007c \
  --color=pointer:#ff007c \
  --color=prompt:#65bcff \
  --color=query:#c8d3f5:regular \
  --color=scrollbar:#589ed7 \
  --color=separator:#ff966c \
  --color=spinner:#ff007c \
"
