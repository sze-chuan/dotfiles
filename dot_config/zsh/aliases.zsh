# General aliases - Used across all systems
# These aliases are sourced in .zshrc

# Shell management
alias reload!='. ~/.zshrc'
alias cls='clear'

# Common tools
alias ld='lazydocker'
alias sshp='ssh -o PubkeyAuthentication=no'

# Directory navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# List aliases - using eza
alias ls='eza --icons --group-directories-first'
alias ll='eza -l --icons --group-directories-first --git'
alias la='eza -la --icons --group-directories-first --git'
alias lt='eza --tree --level=2 --icons'
alias lta='eza --tree --level=2 --icons -a'
alias l='eza -1 --icons'