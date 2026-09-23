---
name: start-ticket
description: Starts Jira ticket work directly in the specified repository, or in a jj workspace for edgeos-ui, and squash-merges PRs with a ticket-prefixed commit message. Use when the user starts a Jira ticket, starts work on a ticket, asks for a workspace, or asks to merge a PR.
---

# Start ticket workflow

## Start work

Work directly in the repository folder by default.

For `edgeos-ui` only, create a **jj workspace** (sibling of the default workspace, never a subdirectory):

```bash
jj workspace add -r 'trunk()' "../<workspace>"
```

Workspace name: `<repo-name>-<jira-ticket-no>-<title>`

Slug `<title>` for the directory (lowercase, hyphens). Example: `edgeos-EDGEOS-1234-add-feature-a`.

Do all `edgeos-ui` ticket changes in that workspace. For every other repository, make ticket changes in its repository folder.

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
