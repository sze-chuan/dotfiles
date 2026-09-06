# Dotfiles

Personal dotfiles managed with [chezmoi](https://chezmoi.io), supporting macOS and Omarchy across two profiles.

| Machine | OS | Profile |
|---|---|---|
| MacBook (Apple Silicon) | macOS 15 | Work |
| Linux desktop | Omarchy (Arch) | Work or Personal |
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
# Edit the managed shell configuration
chezmoi edit ~/.bashrc  # Linux
chezmoi edit ~/.zshrc   # macOS

# Apply changes
chezmoi apply

# Or work directly in the source repo
cd $(chezmoi source-path)
git add . && git commit -m "..." && git push && chezmoi apply
```

## Structure

| Path | Purpose |
|---|---|
| `dot_bashrc.tmpl` | Linux Bash config layered on top of Omarchy defaults |
| `dot_zshrc.tmpl` | macOS Zsh config |
| `dot_zshenv` | macOS Zsh environment variables (XDG, ripgrep, fzf) |
| `dot_zprofile` | macOS login shell PATH |
| `dot_config/zsh/` | Aliases and functions shared by Bash and Zsh |
| `dot_config/mise/config.toml` | mise global tool versions |
| `dot_config/ripgrep/ripgreprc` | macOS ripgrep defaults (smart-case, hidden files) |
| `dot_config/bat/config` | macOS Bat theme and style |
| `dot_config/ghostty/config.tmpl` | Ghostty split keybindings (macOS only) |
| `private_dot_env.tmpl` | Raindrop credentials on all profiles; work credentials on work profiles |
| `.chezmoiignore` | OS/profile-based file gating |
| `run_onchange_configure-mise.sh.tmpl` | Re-runs `mise install` when tool config changes |

## Profiles

Work-specific aliases, functions, and agent skills (except Raindrop) are gated
in `.chezmoiignore`. `.env` is deployed on all profiles for Raindrop and
includes additional credentials only on work profiles.

## Requirements

- **macOS**: Homebrew, then `brew install chezmoi`
- **Arch**: `pacman -S chezmoi`
