# Global configuration
export VISUAL="nvim"
export EDITOR="$VISUAL"
export GPG_TTY=$(tty)
export PATH="/usr/local/bin/:$HOME/.local/bin:/opt/homebrew/opt/rustup/bin:/opt/homebrew/opt/libpq/bin:$PATH"

# Load brew
if [ "$(uname)" = "Linux" ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# Load secrets
source ~/.secrets.sh 

# Enable correction
ENABLE_CORRECTION="true"

# Load zfunc and compinit
fpath+=~/.zfunc
autoload -Uz compinit && compinit

# Load antidote
if [[ -e /opt/homebrew/opt/antidote/share/antidote/antidote.zsh ]]; then
    source /opt/homebrew/opt/antidote/share/antidote/antidote.zsh
else
    source /home/linuxbrew/.linuxbrew/share/antidote/antidote.zsh
fi
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
alias tt="tmux new-session -A -D"
alias v="nvim" 
alias jsoncb="pbpaste | fx"
alias weather="~/go/bin/yr today montpellier"
alias ls="eza --icons=always --group-directories-first --git"
alias lla="ls -la"
alias vale="vale --config ~/.config/vale/.vale.ini"
alias readme-generator="npx readme-md-generator"
alias cz="cz --config ~/.cz.toml"
alias ghce="gh copilot explain"
alias ghcs="gh copilot suggest"
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

# Bind keys
bindkey "^[e" redo

# Prompt
autoload -Uz vcs_info

zstyle ':vcs_info:git:*' formats 'on %B%F{5}%b%f '

preexec() {
  # Only set timer if the command is not empty or just whitespace
  if [[ -n ${1//[[:space:]]/} ]]; then
    CMD_TIMER=$EPOCHREALTIME
  else
    unset CMD_TIMER
  fi
}

precmd() {
  vcs_info
  local elapsed=""
  if [[ -n $CMD_TIMER ]]; then
    local now=$EPOCHREALTIME
    local diff=$(printf "%.0f" "$(echo "$now - $CMD_TIMER" | bc)")
    if (( diff > 1 )); then
      elapsed=" (%F{yellow}${diff}s%f)"
    fi
    unset CMD_TIMER
  fi
  PROMPT="%F{cyan}%B%~%b%f ${vcs_info_msg_0_}%F{2}%B❯%f%b${elapsed} "
}

# Load zoxide
eval "$(zoxide init zsh --cmd cd)"

# Load asdf
export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"

# Atuin
eval "$(atuin init zsh)"

# FZF theme
export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS \
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
