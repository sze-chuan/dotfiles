---
name: pull-request
description: Creates and merges GitHub pull requests. Use when the user asks to create, open, submit, or merge a PR. Creates draft PRs from branch changes and repository templates, and squash-merges with Jira ticket-prefixed commit subjects.
---

# Pull request workflow

Use `gh` for GitHub pull request operations.

## Create a PR

1. Review the branch commits and diff against the repository's base branch.
2. Use the repository's pull request template when one exists. Otherwise, write a short body with `Summary` and `Changes` sections.
3. Describe only changes supported by the commits and diff. It is critically important to explain why the change is being made. If the current conversation in which this skill is invoked has discussed the motivation, be sure to capture this in the pull request body.

Use `<jira-ticket-no> <title>` for the PR title when the work has a Jira ticket. Prefer the Jira title as written; otherwise derive a concise title from the changes without inventing a ticket key.

## Screenshots

When verification captured screenshots of a user-visible change, put them in the template's Screenshots section. Add a Screenshots section when the template has none.

Upload each image as a GitHub attachment and use the returned `user-attachments` URL in the body. On `git.illumina.com`, the `gh` token cannot upload these assets. Follow the `gh-pr-images` skill, which uploads through a signed-in browser. Do not commit the image files, and do not add them under `docs/` or any other path on the branch. Do not print cookies, tokens, or session values.

If the upload cannot be completed, say so in the Screenshots section and leave the files only on the local machine.

## Merge a PR

Squash and merge unless the user requests another merge method. Use this commit subject:

`<jira-ticket-no> <title>`

Example: `EDGEOS-1234 Add feature A`

Use the Jira title as written, with its original spacing and capitalization.

```bash
gh pr merge --squash --subject "<jira-ticket-no> <title>"
```
