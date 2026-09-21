---
name: jira-ticket
description: Start Jira ticket work in a jj workspace and squash-merge PRs with a ticket-prefixed commit message. Use when the user starts a Jira ticket, asks for a workspace, or asks to merge a PR.
---

# Jira ticket workflow

## Start work

Create a **jj workspace** (sibling of the default workspace, never a subdirectory):

```bash
jj workspace add -r 'trunk()' "../<workspace>"
```

Workspace name: `<repo-name>-<jira-ticket-no>-<title>`

Slug `<title>` for the directory (lowercase, hyphens). Example: `edgeos-EDGEOS-1234-add-feature-a`.

Do all ticket changes in that workspace. `cd` there before editing.

If ticket or title is missing, take it from the Jira issue (via Executor). Do not invent a key.

## Merge a PR

Always **squash and merge**. Commit subject:

`<jira-ticket-no> <title>`

Example: `EDGEOS-1234 Add feature A`

Use the Jira title as written (spaces and capitalization), not the workspace slug.

```bash
gh pr merge --squash --subject "<jira-ticket-no> <title>"
```

Do not merge with merge commits or rebase-and-merge unless the user overrides.
