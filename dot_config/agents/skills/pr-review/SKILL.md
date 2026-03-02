---
name: pr-review
description: Creates a git worktree for a PR's branch and switches the working directory to it, then performs a code review against the diff commits relative to the main branch. Uses gwt-add from ~/.config/zsh/git-worktree.zsh. Use when the user wants to review or work on a PR in an isolated worktree.
---

# PR Review

Create a git worktree for a pull request's branch using the `gwt-add` function from `~/.config/zsh/git-worktree.zsh`, switch the working directory into it, then perform a thorough code review of all changes relative to the main branch.

## Workflow

### 1. Determine the PR

If the user provided a PR number or URL, extract the number from it.

If no PR was specified, try to find the PR linked to the current branch:
```bash
gh pr view --json number,headRefName,title 2>/dev/null
```

If no PR is found and no number was provided, ask the user: "Which PR number do you want to review?"

### 2. Fetch PR details

Get the head branch name and title:
```bash
gh pr view <PR-number> --json number,headRefName,title,body,baseRefName
```

Extract `headRefName` (the branch to check out) and `baseRefName` (the base branch, usually `main`).

### 3. Fetch the remote branch

Pull down the latest refs for the PR branch:
```bash
git fetch origin <headRefName>
```

### 4. Create the worktree

Source the worktree helpers and create a new worktree tracking the remote branch:
```bash
source ~/.config/zsh/git-worktree.zsh && gwt-add <headRefName> origin/<headRefName>
```

- If `gwt-add` fails with "Not in a worktree-based repository", stop and tell the user to run `gwt-init` first to convert the repo, then retry.
- If the worktree directory already exists, report the path and skip creation — the worktree was already set up.

### 5. Resolve the worktree path

Compute the path where the new worktree was created:
```bash
dirname "$(git rev-parse --show-toplevel)"
```

The new worktree lives at `<parent-dir>/<headRefName>`.

### 6. Change to the new worktree

Switch the working directory into the new worktree:
```bash
cd "<worktree-path>" && pwd
```

### 7. Confirm worktree setup

Report to the user:
- PR number and title
- Branch name checked out
- Full path of the new worktree (the current directory)

### 8. Gather the diff for review

Get the full diff of all commits in this PR relative to the base branch:
```bash
git log origin/<baseRefName>..HEAD --oneline
git diff origin/<baseRefName>...HEAD
```

Also fetch the PR description for context:
```bash
gh pr view <PR-number> --json body,title,labels,reviewRequests
```

### 9. Perform code review

Review all changes thoroughly and produce a structured code review report covering:

#### Summary
- What this PR does (inferred from commits, diff, and PR description)
- Files changed and overall scope

#### Commit Quality
- Are commit messages clear and descriptive?
- Is each commit logically scoped?

#### Code Quality
- Logic correctness and edge cases
- Error handling and defensive coding
- Code duplication or missed reuse opportunities
- Naming clarity (variables, functions, types)
- Unnecessary complexity

#### Security
- Input validation issues
- Injection risks (SQL, command, XSS, etc.)
- Secrets or credentials accidentally included
- Privilege escalation risks

#### Tests
- Are new/changed code paths covered by tests?
- Are edge cases tested?
- Any missing test scenarios?

#### Suggestions
- Specific, actionable feedback with file path and line references where possible
- Differentiate between blocking issues (must fix) and suggestions (nice to have)

#### Verdict
- Overall assessment: Approve / Request Changes / Needs Discussion
- Summary of any blocking issues

## Rules

- Never force-push, reset, or modify the PR branch — this is a read/review checkout
- If the repo is not in worktree structure (`.bare` not found), stop and advise running `gwt-init`
- Always source `~/.config/zsh/git-worktree.zsh` before calling any `gwt-*` function — do not call git worktree commands directly
- Use `origin/<headRefName>` as the base so the worktree tracks the remote branch exactly
- Base the diff against `origin/<baseRefName>` (not just `main`) to handle PRs targeting non-main branches
