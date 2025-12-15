# Global configuration
export VISUAL="nvim"
export PAGER="bat"
export BAT_PAGER="less -R"
export EDITOR="$VISUAL"
export GPG_TTY=$(tty)
export PATH="$HOME/.local/share/mise/shims:/usr/local/bin/:$HOME/.local/bin:$PATH"

# Load brew
if [ "$(uname)" = "Linux" ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# Enable correction
ENABLE_CORRECTION="true"

# Load zinit
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

# Plugins
zinit snippet OMZL::git.zsh
zinit snippet OMZL::history.zsh
zinit snippet OMZL::completion.zsh
zinit snippet OMZL::key-bindings.zsh
zinit snippet OMZL::directories.zsh
zinit snippet OMZ::plugins/common-aliases
zinit snippet OMZ::plugins/git
zinit snippet OMZ::plugins/extract
zinit load Aloxaf/fzf-tab
zinit load zsh-users/zsh-completions
zinit load zsh-users/zsh-autosuggestions
zinit load zsh-users/zsh-syntax-highlighting
zinit load MichaelAquilina/zsh-you-should-use
zinit load wfxr/forgit

# fzf-tab configuration
# disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false
# set descriptions format to enable group support
# NOTE: don't use escape sequences (like '%F{red}%d%f') here, fzf-tab will ignore them
zstyle ':completion:*:descriptions' format '[%d]'
# set list-colors to enable filename colorizing
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# force zsh not to show completion menu, which allows fzf-tab to capture the unambiguous prefix
zstyle ':completion:*' menu no
# custom fzf flags
# NOTE: fzf-tab does not follow FZF_DEFAULT_OPTS by default
zstyle ':fzf-tab:*' fzf-flags --color=fg:1,fg+:2
# To make fzf-tab follow FZF_DEFAULT_OPTS.
# NOTE: This may lead to unexpected behavior since some flags break this plugin. See Aloxaf/fzf-tab#455.
zstyle ':fzf-tab:*' use-fzf-default-opts yes
# switch group using `<` and `>`
zstyle ':fzf-tab:*' switch-group '<' '>'
# use tmux popup for fzf
zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
# Min size apply to all command
zstyle ':fzf-tab:*' popup-min-size 200 8
# preview directory's content with eza when completing cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
# Preview command
zstyle ':fzf-tab:complete:-command-:*' fzf-preview \
  '(out=$(tldr --color always "$word") 2>/dev/null && echo $out) || (out=$(MANWIDTH=$FZF_PREVIEW_COLUMNS man "$word") 2>/dev/null && echo $out) || (out=$(which "$word") && echo $out) || echo "${(P)word}"'

# Custom title
DISABLE_AUTO_TITLE="true"

# Aliases
export DOTFILES_DIRECTORY="$HOME/dotfiles"
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

# Notification function
function dialog() {
  local title="${1:-Notification}"
  local message="${2:-Your message here}"
  osascript -e "display dialog \"$message\" with title \"$title\" buttons {\"OK\"} default button 1" > /dev/null
}
function notify() {
  local cmdstatus=$?
  local title message
  local last_cmd="${LAST_CMD:-Unknown command}"

  if [[ $cmdstatus -eq 0 ]]; then
    title="✓ Success"
    message="${1:-$last_cmd}"
  else
    title="✗ Failed (exit $cmdstatus)"
    message="${1:-$last_cmd}"
  fi

  dialog "$title" "$message"
  return $cmdstatus
}

# Yazi explorer
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

# Find process listening on a port
function whoseport() { lsof -i :$1 -sTCP:LISTEN -t | xargs -r ps -o pid=,comm= -p; }

# Docker custom commands
function docker() {
  if [[ "$1" == "stop" && "$2" == "all" ]]; then
    command docker stop $(command docker ps -a -q)
  elif [[ "$1" == "rm" && "$2" == "all" ]]; then
    command docker rm $(command docker ps -a -q)
  else
    command docker "$@"
  fi
}

# I want clear to also clear the scrollback in tmux or nvim
if [[ -n "$NVIM" ]]; then
  alias clear="nvim --server \"\$NVIM\" --remote-send '<Cmd>lua require(\"toggleterm\").exec(\"exit\", 1)<CR><Cmd>lua vim.defer_fn(function() require(\"toggleterm\").toggle() end, 200)<CR>'"
elif [ -n "$TMUX" ]; then
  alias clear='clear && tmux clear-history'
fi

# Bind keys
bindkey "^[e" redo

# Home/End keys (for Ghostty Command+Left/Right)
bindkey "^[OH" beginning-of-line
bindkey "^[OF" end-of-line

# Word navigation (for Ghostty Alt+Left/Right)
bindkey "^[[1;3D" backward-word
bindkey "^[[1;3C" forward-word

# Prompt
autoload -Uz vcs_info

zstyle ':vcs_info:git:*' formats 'on %B%F{5}%b%f '

preexec() {
  local action="$1"

  # Set window title
  echo -ne "\033]0;$action - ${PWD##*/}\a"

  # Capture command for notify
  LAST_CMD="$1"

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
    local diff=$(( now - CMD_TIMER ))
    if (( diff > 1 )); then
      printf -v elapsed "(%s%.2fs%s) " "%F{yellow}" "$diff" "%f"
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
  --bind alt-up:preview-up,alt-down:preview-down \
  --bind alt-shift-up:preview-page-up,alt-shift-down:preview-page-down \
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

# Load zfunc and compinit (optimized: only once per day)
autoload -Uz compinit
if [[ -n ${ZDOTDIR}/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi
