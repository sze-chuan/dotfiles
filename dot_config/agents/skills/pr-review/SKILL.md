---
name: pr-review
description: Performs a code review of a pull request against the diff commits relative to the main branch. Use when the user wants to review a PR.
---

# PR Review

Perform a thorough code review of all changes in a pull request relative to the main branch.

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

### 3. Gather the diff for review

Get the full diff of all commits in this PR relative to the base branch:
```bash
git log origin/<baseRefName>..HEAD --oneline
git diff origin/<baseRefName>...HEAD
```

Also fetch the PR description for context:
```bash
gh pr view <PR-number> --json body,title,labels,reviewRequests
```

### 4. Perform code review

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
- Base the diff against `origin/<baseRefName>` (not just `main`) to handle PRs targeting non-main branches
