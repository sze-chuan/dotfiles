---
name: create-pr
description: Creates a draft GitHub pull request using the repo's PR template and a summary of local branch commits. Use when the user asks to create a PR, open a pull request, or submit changes for review.
---

# Create Pull Request

## Workflow

### 1. Gather branch context

Run these in parallel:
- `git log main...HEAD --oneline` — list commits on this branch
- `git diff main...HEAD --stat` — summarise files changed
- `git branch --show-current` — confirm current branch name
- Check if a remote tracking branch exists: `git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || echo "no-upstream"`

### 2. Load the PR template

Look for a PR template in the repo root:
```
.github/pull_request_template.md
.github/PULL_REQUEST_TEMPLATE.md
```

If no template is found, use a minimal default:
```markdown
## Summary

## Changes

```

### 3. Populate the template

Fill in the template sections using the commit history and diff stats:
- **Summary**: 1–3 bullet points describing *why* these changes were made (not just what files changed)
- **Changes** (if the template has it): What was added, modified, or removed

Do not invent content — only summarise what is visible in the commits and diff.

### 4. Push branch if needed

If the branch has no upstream, push it first:
```bash
git push -u origin <branch-name>
```

### 5. Create the draft PR

Use `gh pr create` with:
- `--draft` flag (always create as draft unless the user explicitly says otherwise)
- `--title`: use `EDGEOS-<ticket-number> <brief description>`. `<ticket number>` can be referenced from branch name 
- `--body`: the populated template passed via a HEREDOC

```bash
gh pr create --draft --title "<title>" --body "$(cat <<'EOF'
<populated template>
EOF
)"
```

### 6. Return the PR URL

After creation, output the PR URL so the user can review and publish it.

## Rules

- Always create as **draft** unless user says "ready for review" or "not draft"
- Never force-push or reset to make a push succeed — report the conflict to the user instead
- Do not guess at test results or claim tests pass without evidence
- Keep the PR title under 70 characters
- Use imperative mood in the title ("Add feature X", "Fix bug Y", "Remove deprecated Z")
