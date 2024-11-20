# Load antigen
source "$HOME"/.antigen.zsh

# Make sure completion directoy exist
#mkdir -p "$HOME"/.antigen/bundles/robbyrussell/oh-my-zsh/cache/completions/

# Install oh-my-zsh
antigen use oh-my-zsh

# Custom title
DISABLE_AUTO_TITLE="true"
preexec() {
  local action="$1"
  echo -ne "\033]0;$action - ${PWD##*/}\a"
}

# Enable correction
ENABLE_CORRECTION="true"

# oh-my-zsh plugins
antigen bundle git
antigen bundle fzf
antigen bundle docker-compose
antigen bundle docker
antigen bundle gitignore
antigen bundle golang
antigen bundle history
antigen bundle kubectl
antigen bundle npm
antigen bundle nvm
antigen bundle rust
antigen bundle terraform

# Custom plugins
antigen bundle Aloxaf/fzf-tab
antigen bundle zsh-users/zsh-completions
antigen bundle zsh-users/zsh-autosuggestions
antigen bundle zsh-users/zsh-syntax-highlighting

# Load the theme
antigen theme robbyrussell

# Apply antigen
antigen apply
