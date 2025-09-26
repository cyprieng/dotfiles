# Global configuration
export VISUAL="nvim"
export EDITOR="$VISUAL"
export GPG_TTY=$(tty)
export PATH="/usr/local/bin/:$HOME/.local/bin:/opt/homebrew/opt/rustup/bin:/opt/homebrew/opt/libpq/bin:$PATH"
export DOCKER_HOST="unix://$HOME/.colima/docker.sock"

# Load brew
if [ "$(uname)" = "Linux" ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# nvm
export NVM_DIR="$HOME/.nvm"
export HOMEBREW_PREFIX="$(brew --prefix)"

nvm_lazy_load() {
  unset -f nvm node npm npx
  [ -s "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" ] && \. "$HOMEBREW_PREFIX/opt/nvm/nvm.sh"
}

for cmd in nvm node npm npx; do
  eval "
  $cmd() {
    nvm_lazy_load
    $cmd \"\$@\"
  }
  "
done

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
alias g="git" 
alias ls="eza --icons=always --group-directories-first --git"
alias lla="ls -la"
alias cz="cz --config ~/.cz.toml"
alias ghce="gh copilot explain"
alias ghcs="gh copilot suggest"
alias load.env="set -a && source .env && set +a"
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}
whoseport() { lsof -i :$1 -sTCP:LISTEN -t | xargs -r ps -o pid=,comm= -p; }

# I want clear to also clear the scrollback in tmux or nvim
if [[ -n "$NVIM" ]]; then
  alias clear="nvim --server \"\$NVIM\" --remote-send '<Cmd>lua require(\"toggleterm\").exec(\"exit\", 1)<CR><Cmd>lua vim.defer_fn(function() require(\"toggleterm\").toggle() end, 200)<CR>'"
elif [ -n "$TMUX" ]; then
  alias clear='clear && tmux clear-history'
fi

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
    local diff=$(printf "%.2f" "$(echo "$now - $CMD_TIMER" | bc)")
    if (( diff > 1 )); then
      elapsed="(%F{yellow}${diff}s%f) "
    fi
    unset CMD_TIMER
  fi
  PROMPT="%F{cyan}%B%~%b%f ${vcs_info_msg_0_}${elapsed}%F{2}%B❯%f%b "
}

# Load zoxide
eval "$(zoxide init zsh --cmd cd)"

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
