---
name: sprint-summary
description: "Drafts a sprint preview/heads-up message for the team by fetching issues from Jira and generating a structured summary. Use when preparing a sprint overview or heads-up before a sprint starts."
---

# Sprint Summary

Generate a sprint preview message for the UI Ninjas team by pulling issues from Jira and drafting a structured summary.

## Prerequisites

- `JIRA_PAT` environment variable set with a valid Jira Personal Access Token
- `jq` installed
- `curl` installed

## Workflow

### 1. Get sprint name

Ask the user for the sprint name (e.g., "Sprint 26.1.4").

### 2. Fetch sprint issues

Run the fetch script and save output to a temp file:

```bash
~/.config/agents/skills/sprint-summary/fetch-sprint-issues.sh "<sprint-name>" > /tmp/sprint-issues.json
```

If the script fails, check the exit code:
- **1**: Missing sprint name argument
- **2**: `JIRA_PAT` not set — ask the user to export it
- **3**: Jira API error — show the error and ask the user to verify the sprint name

### 3. Parse and categorise issues

Read `/tmp/sprint-issues.json` and organise issues into categories:

**Categorise by issue type** (`fields.issuetype.name`):
- **Features**: Story, Feature
- **Bugs and tech improvements**: Bug, Task, Tech Improvement, Sub-task

For each issue, extract:
- `key` — Jira issue key (e.g., EDGEOS-1234)
- `fields.summary` — issue title
- `fields.issuetype.name` — type
- `fields.status.name` — current status
- `fields.priority.name` — priority level
- `fields.assignee.displayName` — who is assigned
- `fields.labels` — labels array
- `fields.issuelinks` — linked issues (look for blocking relationships)
- `fields.epicName` — resolved epic name (injected by fetch script from `customfield_10006`)

### 4. Draft the summary

Use this template:

```markdown
Sprint <name> overview

Hi UI Ninjas, here's a heads up on the upcoming sprint next week.

## Overview

### Features
- <Epic name>
- <Epic name>
- <ISSUE-KEY> <summary> (only for issues without an epic)

### Bugs and tech improvements
- <ISSUE-KEY> <summary>

## Focus
- *[User-provided]*

## Notes and thoughts
- *[User-provided]*
```

Guidelines for Features:
- If an issue has an `epicName`, display the epic name only (not the ticket key). Deduplicate — each epic appears once even if multiple issues share it.
- If an issue has no epic, fall back to `<KEY> <summary>`.
- List epics first, then individual tickets without epics.

Guidelines for Bugs and tech improvements:
- List as `<KEY> <summary>` — keep it scannable.

Focus and Notes sections:
- Leave as placeholders for the user to fill in. Do not auto-generate focus items.

### 5. Ask user for notes

Present the draft to the user and ask:
- Any items to add, remove, or change?
- Content for the Focus and Notes sections?

### 6. Present final summary

Apply the user's feedback and present the final markdown summary, ready to copy into Slack or email.

## Rules

- Do not fabricate issue data — only use what comes from the Jira API response
- Keep the summary concise and scannable — bullet points, not paragraphs
- Group related issues together when it aids readability
- If there are no issues in a category, omit that category header entirely
- If the fetch returns zero issues, tell the user and ask them to verify the sprint name
