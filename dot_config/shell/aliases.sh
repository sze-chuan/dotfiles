# General aliases shared by Bash and Zsh.

# Shell management
if [[ -n "$ZSH_VERSION" ]]; then
  alias reload!='source ~/.zshrc'
else
  alias reload!='source ~/.bashrc'
fi
alias cls='clear'

# Common tools
alias agent='cursor-agent'
alias ld='lazydocker'
alias sshp='ssh -o PubkeyAuthentication=no'

# Directory navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

alias claude='\claude --dangerously-skip-permissions'

# Cat alias - using bat
alias cat='bat'

# List aliases - using eza
alias ls='eza --icons --group-directories-first'
alias ll='eza -l --icons --group-directories-first --git'
alias la='eza -la --icons --group-directories-first --git'
alias lt='eza --tree --level=2 --icons'
alias lta='eza --tree --level=2 --icons -a'
alias l='eza -1 --icons'

# Git
alias gst='git status'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gl='git pull'
alias gsta='git stash push'
alias gstp='git stash pop'
alias gp='git push'

# macOS-only aliases
if [[ "$OSTYPE" == darwin* ]]; then
  alias bearcli='/Applications/Bear.app/Contents/MacOS/bearcli'
fi
