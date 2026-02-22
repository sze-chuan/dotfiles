# Dotfiles

Personal dotfiles managed with [chezmoi](https://chezmoi.io), supporting three machines across two profiles.

| Machine | OS | Profile |
|---|---|---|
| MacBook (Apple Silicon) | macOS 15 | Work |
| Linux desktop | Omarchy (Arch) | Personal |
| Linux server | Oracle Enterprise Linux 9 | Work |

## Fresh Machine Setup

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply sze-chuan/dotfiles
```

Chezmoi auto-detects the OS/distro and applies the correct profile. Unknown distros prompt for profile selection.

## Daily Workflow

```sh
# Edit a managed file
chezmoi edit ~/.zshrc

# Apply changes
chezmoi apply

# Or work directly in the source repo
cd $(chezmoi source-path)
git add . && git commit -m "..." && git push && chezmoi apply
```

## Structure

| Path | Purpose |
|---|---|
| `dot_zshrc.tmpl` | Zsh config (OS-conditional via chezmoi template) |
| `dot_zshenv` | Env vars available to all processes (XDG, ripgrep, fzf) |
| `dot_zprofile` | Login shell PATH |
| `dot_config/zsh/` | Aliases, functions, git worktree helpers |
| `dot_config/mise/config.toml` | mise global tool versions |
| `dot_config/ripgrep/ripgreprc` | ripgrep defaults (smart-case, hidden files) |
| `dot_config/bat/config` | bat theme and style |
| `dot_config/ghostty/config.tmpl` | Ghostty terminal config (macOS only) |
| `dot_env.tmpl` | Secrets/credentials (not committed in plaintext) |
| `.chezmoiignore` | OS/profile-based file gating |
| `run_onchange_configure-mise.sh.tmpl` | Re-runs `mise install` when tool config changes |

## Profiles

Work-specific files (`work-aliases.zsh`, `work-functions.zsh`, `.env`) are gated in `.chezmoiignore` and only deployed on work machines (macOS, OEL9).

## Requirements

- **macOS**: Homebrew, then `brew install chezmoi`
- **Arch**: `pacman -S chezmoi`
- **OEL9**: `dnf install chezmoi` or `brew install chezmoi`
