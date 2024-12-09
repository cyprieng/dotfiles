# Global configuration
export VISUAL="nvim"
export EDITOR="$VISUAL"
export GPG_TTY=$(tty)
export PATH="$HOME/.local/bin:$PATH"

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
