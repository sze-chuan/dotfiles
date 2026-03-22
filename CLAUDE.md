# MacOS/Linux System Configuration Assistant

## System Context

I am running a MacOS/Linux system and need help with configuration, setup, and administration tasks. Please assist me following MacOS/Linux best practices and respecting system defaults.

## Current System Information

### Machines

| Machine | OS | Profile | Notes |
|---|---|---|---|
| MacBook (Apple Silicon) | macOS 15.7 | Work | Illumina / EdgeOS development |
| Linux desktop | Omarchy (Arch-based) | Personal | Personal use only |
| Linux server | Oracle Enterprise Linux 9 | Work | Illumina / EdgeOS development |

Profile is determined by the `is_work` chezmoi parameter, not OS.

- **Home Directory**: $HOME
- **Working Directory**: Check with `pwd` before making assumptions

## Core Principles

### CRITICAL RULES

1. **Push file changes via chezmoi after modifications**
1. **NEVER modify system files without explicit permission**
1. **Check for existing configurations before creating new ones**
1. **Follow the principle of least privilege** - Use sudo only when necessary
1. **Document all changes made to the system**

### Configuration Hierarchy (DO NOT VIOLATE)

1. User-specific configs in `~/.config/` (preferred)
2. User home directory dotfiles `~/.*` (legacy)
3. System-wide configs in `/etc/` (requires sudo, avoid when possible)
4. Default configs in `/usr/share/` (NEVER modify)

## Best Practices

### Before Making Any Changes

1. **Investigate current state:**

   ```bash
   # Check if configuration already exists
   ls -la ~/.config/[application]/
   find ~ -name "*[application]*" -type f 2>/dev/null

   # Look for example/default files
   find /usr/share -name "*[application]*" -type f 2>/dev/null
   find /etc -name "*[application]*" -type f 2>/dev/null
   ```

2. **Test changes:**
   - Make incremental changes
   - Test after each change
   - Have a rollback plan

## Common Tasks Approach

### Installing Software

1. For macOS, use Homebrew
2. For Omarchy (Arch), use pacman/yay only — do not use Homebrew
3. For Oracle Enterprise Linux 9, prefer dnf, fall back to Homebrew
4. Manual installation as last resort
5. Document installation method for future updates

### Configuration Files

1. Use proper format (YAML, TOML, JSON, INI) as expected by application
2. Include comments explaining customizations
3. Keep original structure intact
4. Use includes/sources when possible instead of modifying main files

### Environment Variables

```bash
# Session-wide (preferred)
~/.config/environment.d/*.conf

# Shell-specific
~/.bashrc or ~/.zshrc

# System-wide (avoid)
/etc/environment
```

## Task Request Format

When asking for help, I'll provide:

- What I want to accomplish
- Any specific constraints or preferences
- What I've already tried (if applicable)

Example requests:

- "Help me configure [application] properly"
- "I need to set up [service] to start automatically"
- "Show me how to install and configure [tool]"
- "Debug why [application] isn't working"
- "Optimize [system component] for better performance"

## Safety Guidelines

### Always

- Check file permissions after creating/modifying configs
- Verify syntax before applying configuration changes
- Keep a session open when modifying network/SSH configs
- Test commands with `echo` or `--dry-run` first when available
- Use version control for important configs

### Never

- Run commands with sudo unless absolutely necessary
- Pipe curl/wget directly to bash without reviewing
- Modify files in /usr/ or /boot/ without explicit need
- Delete files without understanding their purpose
- Disable security features without good reason

## Dotfiles Management with Chezmoi

My dotfiles are managed with chezmoi and backed up to GitHub at `sze-chuan/dotfiles`.

### Work/personal profiles

- Profile is set via the `is_work` boolean parameter, prompted once during `chezmoi init` and persisted in `~/.config/chezmoi/chezmoi.toml`
- Work-specific configs (work-aliases, work-functions, `.env`) are gated behind `{{ .is_work }}` in templates and `.chezmoiignore`
- To change profile on an existing machine, update `is_work` in `~/.config/chezmoi/chezmoi.toml` and run `chezmoi apply`
- Reference chezmoi's [user guide](https://www.chezmoi.io/user-guide/command-overview/) for managing profiles

### After modifying configuration files

Always push changes using chezmoi after file modifications:

```bash
$(chezmoi source-path) && git add . && git commit -m "Your commit message" && git push && chezmoi apply
```

This applies to:

- Editing configuration files
- Creating new configuration files
- Deleting configuration files
- Modifying CLAUDE.md itself
- Any file operation in tracked directories

Replace "Your commit message" with a description of your changes.

## Documentation

After making changes:

1. Document what was changed and why
2. Note any dependencies or requirements
3. Include rollback procedures
4. Save relevant commands for future reference
5. Commit configuration changes to dotfiles repo if applicable

## Final Notes

- Prefer simple solutions over complex ones
- Use native tools when possible
- Follow distribution-specific conventions
- Test in a safe environment when possible
- Ask for clarification if requirements are unclear

Please help me with my MacOS/Linux system configuration and administration tasks following these guidelines.
