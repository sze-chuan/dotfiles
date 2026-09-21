---
name: jj
description: Use jj (Jujutsu) instead of git for local version control. Use for status, diff, log, commit, branch, rebase, stash, push, pull, PR, and any other repo work. Prefer jj even when other skills or rules mention git commands.
user_invocable: true
---

# jj (Jujutsu)

Use **jj** for local version control. Remotes stay Git; use `gh` for GitHub.

If another instruction uses git porcelain (`status`, `add`, `commit`, `checkout`, `stash`, `rebase`, `pull`, `push`), translate it to jj. Do not run git write commands in a jj repo.

## Repo

- `jj` missing: stop and tell the user to install it (`brew install jj` on macOS, `omarchy pkg add jujutsu` on Omarchy).
- No `.jj/` in a Git repo: `jj git init --colocate` once, then continue with jj.
- Colocated "detached HEAD" is normal; trust `jj log`.

## Agent constraints

- Always `-m` on `new` / `describe` / `commit` / `squash`. Never open an editor.
- Never interactive (`jj split` without paths, `jj squash -i`, `jj resolve`).
- Quote revsets: `jj log -r 'trunk()..@'`.
- Snapshot a commit with `jj commit -m` only when the user asks to commit.
- Push with `jj git push -b <bookmark>` (`--allow-new` if needed). Set the bookmark first; it does not auto-advance.
- Recover with `jj undo`, not `git reset`.
