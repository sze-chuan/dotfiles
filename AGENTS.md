# Dotfiles Configuration

This repository manages user configuration with [chezmoi](https://www.chezmoi.io/).
The source checkout is `~/repos/dotfiles`.

## Machines and profiles

| Machine | OS | Profile |
|---|---|---|
| MacBook (Apple Silicon) | macOS | Work |
| Linux server | Oracle Enterprise Linux 9 | Work |
| Linux desktop | Omarchy (Arch) | Personal |
| Personal Mac | macOS | Personal |

The `is_work` chezmoi parameter selects the profile; it is prompted once during
`chezmoi init` and stored in `~/.config/chezmoi/chezmoi.toml`. Do not infer the
profile from the operating system.

## Profile boundaries

- Raindrop and `~/.env` apply to both profiles. `private_dot_env.tmpl` deploys
  `~/.env` owner-private; never print its rendered credentials.
- Work-only: work zsh aliases/functions, Cursor CLI configuration, and the
  `acceptance-criteria`, `create-pr`, `pr-review`, and `sprint-summary` skills.
- `raindrop` is the only bundled personal skill.

## Platform rules

- **macOS:** use Homebrew.
- **Omarchy:** use pacman/yay only; do not use Homebrew. Preserve Omarchy's
  Ghostty configuration—do not manage `~/.config/ghostty` there.
- **OEL 9:** prefer dnf and use Homebrew only when needed.
- Never modify `/usr/share/`, `/etc/`, or other system configuration without
  explicit user approval.

## Chezmoi workflow

Before applying changes, preview them:

```sh
chezmoi apply --dry-run --verbose
```

`chezmoi apply` may run bootstrap scripts that install packages and, on
Omarchy, enable Tailscale SSH. Require explicit user approval before applying
or running privileged commands.

When the user asks to publish source changes:

```sh
cd "$(chezmoi source-path)"
git add .
git commit -m "<description>"
git push
chezmoi apply
```

Use `chezmoi diff` to inspect deployed-state changes. After editing a managed
file, confirm its syntax or behavior before applying it when practical.
