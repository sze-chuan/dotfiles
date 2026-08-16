# Dotfiles

Personal dotfiles managed with [chezmoi](https://chezmoi.io), supporting four machines across two profiles.

| Machine | OS | Profile |
|---|---|---|
| MacBook (Apple Silicon) | macOS 15 | Work |
| Linux server | Oracle Enterprise Linux 9 | Work |
| Linux desktop | Omarchy (Arch) | Personal |
| Personal Mac | macOS | Personal |

## Fresh Machine Setup

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply sze-chuan/dotfiles
```

Chezmoi prompts once for the work/personal profile and stores the choice in
`~/.config/chezmoi/chezmoi.toml`. OS and distro determine package-manager and
configuration behavior, not the profile.

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
| `dot_config/ghostty/config.tmpl` | Ghostty split keybindings (macOS only) |
| `private_dot_env.tmpl` | Raindrop credentials on all profiles; work credentials on work profiles |
| `.chezmoiignore` | OS/profile-based file gating |
| `run_onchange_configure-mise.sh.tmpl` | Re-runs `mise install` when tool config changes |

## Profiles

Work-specific files (`work-aliases.zsh`, `work-functions.zsh`, Cursor CLI
configuration, and all agent skills except Raindrop) are gated in
`.chezmoiignore`. `.env` is deployed on all profiles for Raindrop and includes
additional credentials only on work profiles.

## Requirements

- **macOS**: Homebrew, then `brew install chezmoi`
- **Arch**: `pacman -S chezmoi`
- **OEL9**: `dnf install chezmoi` or `brew install chezmoi`
