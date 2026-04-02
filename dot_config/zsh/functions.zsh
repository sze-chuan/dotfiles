# General functions - Used across all systems
# These functions are sourced in .zshrc

# Source git worktree management functions
[[ -f "$XDG_CONFIG_HOME/zsh/git-worktree.zsh" ]] && source "$XDG_CONFIG_HOME/zsh/git-worktree.zsh"

# Ghostty theme switcher
# Themes: https://ghostty.org/docs/config/reference#theme
# Run `ghostty +list-themes` to see all available themes
GHOSTTY_DARK_THEME="Catppuccin Mocha"
GHOSTTY_LIGHT_THEME="Catppuccin Latte"

_ghostty_set_theme() {
  local theme="$1"
  local config="${HOME}/.config/ghostty/config"
  if grep -q '^theme' "$config" 2>/dev/null; then
    sed -i '' "s|^theme =.*|theme = ${theme}|" "$config"
  else
    printf '\ntheme = %s\n' "${theme}" >> "$config"
  fi
  # Trigger reload via keybind (super+ctrl+r=reload_config must be set in ghostty config)
  osascript -e 'tell application "System Events" to tell process "ghostty" to keystroke "r" using {command down, control down}' 2>/dev/null
  echo "Ghostty theme set to: ${theme}"
}

ghd() { _ghostty_set_theme "$GHOSTTY_DARK_THEME"; }
ghl() { _ghostty_set_theme "$GHOSTTY_LIGHT_THEME"; }