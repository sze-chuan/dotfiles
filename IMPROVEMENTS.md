# Dotfiles Improvement Recommendations

Audit performed: 2026-02-22

## 1. Chezmoi — Underutilized Features

### Add `.chezmoiignore` for OS/profile separation
Work-specific files (`work-aliases.zsh`, `work-functions.zsh`) deploy to all machines
unconditionally. Use `.chezmoiignore` to gate them:

```
# .chezmoiignore
{{ if ne .chezmoi.os "darwin" }}
dot_config/ghostty/
{{ end }}

{{ if not .is_work }}
dot_config/zsh/work-aliases.zsh
dot_config/zsh/work-functions.zsh
{{ end }}
```

### Add `run_once_` bootstrap scripts
No documented path from fresh machine to working setup. Add chezmoi run scripts:
- `run_once_install-packages.sh.tmpl` — install brew, eza, mise, ghostty, etc.
- `run_onchange_configure-mise.sh.tmpl` — install tool versions after config changes

### Use `.chezmoiexternal` for external dependencies
Manage antidote, p10k, or plugin repos through chezmoi rather than relying on brew.

### Convert `dot_zshrc` to a template
Currently hardcodes `$(brew --prefix)` which fails on Linux without brew.
Should be `dot_zshrc.tmpl` with OS-conditional paths.

## 2. Shell Configuration — Robustness

### Slow brew --prefix on every shell start
`dot_zshrc:13` runs `brew --prefix` on each shell launch (~200ms penalty).
Cache the result or hardcode per-OS in a template.

### Unnecessary mise bash activation
`dot_zshrc:21` activates mise for bash inside zsh config. Likely a mistake — only the
zsh activation on line 22 is needed.

### Missing explicit history settings
Relying entirely on `belak/zsh-utils` for HISTFILE/HISTSIZE/SAVEHIST. Explicit settings
are more resilient to plugin changes.

### PATH duplication on reload
Amp CLI, opencode, and claude PATH entries (`dot_zshrc:33-39`) accumulate on `reload!`.
Move to `.zshenv`/`.zprofile` or add deduplication.

### Move XDG vars to `.zshenv`
XDG_CONFIG_HOME etc. are set in `.zshrc` but should be in `.zshenv` so non-interactive
shells and other programs can access them.

## 3. Portability — macOS/Linux

### BSD sed in work functions
`connect-ui-dev` uses `sed -i ''` (macOS-only). Fails on Linux. Use conditional logic
or a portable alternative.

### No Linux terminal configuration
Ghostty config is macOS-only. No terminal config exists for Linux.

## 4. Security

### `--dangerously-skip-permissions` in alias
`aliases.zsh:18` — the `jarvis` alias permanently skips all Claude permission checks.
Consider removing the flag or using a scoped permissions config.

### Hardcoded postgres password in alias
`work-aliases.zsh:5` — `POSTGRES_PASSWORD=password` in version control. Use an env var.

### Plaintext secrets on disk
`dot_env.tmpl` writes JIRA_PAT to `~/.env`. Consider using a secrets manager
(1Password CLI `op run`, or chezmoi's built-in secret management).

## 5. Git Configuration

### No managed global gitignore
`core.excludesfile = ~/.gitignore` is set but no `dot_gitignore` exists in dotfiles.
Add one with: `.DS_Store`, `*.swp`, `.env`, `.idea/`, `.vscode/`, `node_modules/`.

### Missing merge conflict style
Add `merge.conflictStyle = zdiff3` for better three-way conflict markers.

### Missing transfer fsck
Add `transfer.fsckObjects = true` to catch corrupt objects on fetch/push.

## 6. Missing Tool Configurations

- **mise global config** (`~/.config/mise/config.toml`) — tool versions not reproducible
- **ripgrep config** — smart-case, hidden files, common ignores
- **fzf defaults** — `FZF_DEFAULT_OPTS` and `FZF_DEFAULT_COMMAND` with fd/rg integration
- **bat config** — theme and style settings if using bat

## 7. Structure & Maintenance

### `dot_p10k.zsh` is 89KB generated file
Creates noisy diffs. Consider `.gitattributes linguist-generated` or moving to external.

### No bootstrap documentation
No README or Makefile documenting how to set up from scratch.

---

## Highest Priority

1. **Convert `dot_zshrc` to chezmoi template** — fixes Linux portability
2. **Add `.chezmoiignore`** — prevents work configs on personal machines
3. **Add `run_once_` bootstrap script** — makes dotfiles reproducible
