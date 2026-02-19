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

**Identify focus items** — issues that need attention:
- Blocked issues: `issuelinks` entries where `type.name` is "Blocks" and the issue is the inward (blocked) side
- High priority: `priority.name` is "High" or "Highest"
- In testing/review: `status.name` contains "Test", "Review", or "QA"

### 4. Draft the summary

Use this template:

```markdown
Sprint <name> overview

Hi UI Ninjas, here's a heads up on the upcoming sprint next week.

## Overview

### Features
- <ISSUE-KEY> <summary>

### Bugs and tech improvements
- <ISSUE-KEY> <summary>

## Focus
- <Auto-drafted bullet points from high-priority, blocked, or in-testing items with brief context>

## Notes and thoughts
- <Placeholder for user content>
```

Guidelines:
- List issues as `<KEY> <summary>` — keep it scannable
- In the Focus section, explain *why* each item needs attention (e.g., "blocked by EDGEOS-999", "high priority", "currently in QA")
- Leave the Notes section with placeholder bullets for the user to fill in

### 5. Ask user for notes

Present the draft to the user and ask:
- Any notes or thoughts to include in the "Notes and thoughts" section?
- Any items to add, remove, or re-prioritise in the Focus section?
- Any other changes?

### 6. Present final summary

Apply the user's feedback and present the final markdown summary, ready to copy into Slack or email.

## Rules

- Do not fabricate issue data — only use what comes from the Jira API response
- Keep the summary concise and scannable — bullet points, not paragraphs
- Group related issues together when it aids readability
- If there are no issues in a category, omit that category header entirely
- If the fetch returns zero issues, tell the user and ask them to verify the sprint name
