# Load antidote
source /opt/homebrew/opt/antidote/share/antidote/antidote.zsh
source <(antidote init)

# Bundle oh-my-zsh libs and plugins with the 'path:' annotation
antidote bundle getantidote/use-omz
antidote bundle ohmyzsh/ohmyzsh path:lib
antidote bundle ohmyzsh/ohmyzsh path:plugins/git
antidote bundle ohmyzsh/ohmyzsh path:plugins/extract
antidote bundle ohmyzsh/ohmyzsh path:plugins/fzf
antidote bundle ohmyzsh/ohmyzsh path:plugins/docker-compose
antidote bundle ohmyzsh/ohmyzsh path:plugins/docker
antidote bundle ohmyzsh/ohmyzsh path:plugins/gitignore
antidote bundle ohmyzsh/ohmyzsh path:plugins/golang
antidote bundle ohmyzsh/ohmyzsh path:plugins/history
antidote bundle ohmyzsh/ohmyzsh path:plugins/kubectl
antidote bundle ohmyzsh/ohmyzsh path:plugins/npm
antidote bundle ohmyzsh/ohmyzsh path:plugins/nvm
antidote bundle ohmyzsh/ohmyzsh path:plugins/rust
antidote bundle ohmyzsh/ohmyzsh path:plugins/terraform

# Other plugins
antidote bundle Aloxaf/fzf-tab
antidote bundle zsh-users/zsh-completions
antidote bundle zsh-users/zsh-autosuggestions
antidote bundle zsh-users/zsh-syntax-highlighting

# Custom title
DISABLE_AUTO_TITLE="true"
preexec() {
  local action="$1"
  echo -ne "\033]0;$action - ${PWD##*/}\a"
}

# Enable correction
ENABLE_CORRECTION="true"

# Load the theme
eval "$(starship init zsh)"
