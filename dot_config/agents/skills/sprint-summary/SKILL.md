---
name: sprint-summary
description: "Drafts a sprint preview/heads-up message for the team, or generates statistics across multiple sprints, by fetching issues from Jira. Use when preparing a sprint overview or analysing sprint data."
---

# Sprint Summary

Assist the UI Ninjas team with sprint data from Jira. Supports two modes:
- **Summary** — draft a heads-up message for an upcoming sprint
- **Stats** — generate ticket statistics across one or more sprints

## Prerequisites

- `JIRA_PAT` environment variable set with a valid Jira Personal Access Token
- `jq` installed
- `curl` installed

## Workflow

### 1. Select mode

Ask the user which mode they want:
- **Summary** — upcoming sprint heads-up
- **Stats** — statistics across multiple sprints

Then follow the corresponding workflow below.

---

## Mode: Summary

### S1. Get sprint name

Ask the user for the sprint name (e.g., "26.1.4").

### S2. Fetch sprint issues

Run the fetch script and save output to a temp file:

```bash
~/.config/agents/skills/sprint-summary/fetch-sprint-issues.sh "<sprint-name>" > /tmp/sprint-issues.json
```

If the script fails, check the exit code:
- **1**: Missing sprint name argument
- **2**: `JIRA_PAT` not set — ask the user to export it
- **3**: Jira API error — show the error and ask the user to verify the sprint name

### S3. Parse and categorise issues

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

### S4. Draft the summary

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

### S5. Ask user for notes

Present the draft to the user and ask:
- Any items to add, remove, or change?
- Content for the Focus and Notes sections?

### S6. Present final summary

Apply the user's feedback and present the final markdown summary, ready to copy into Slack or email.

---

## Mode: Stats

### T1. Get sprint list

Ask the user for one or more sprint names to include (e.g., `26.1.2`, `26.1.3`, `26.1.4`).

### T2. Fetch issues per sprint

For each sprint, run the fetch script and save to a numbered temp file:

```bash
~/.config/agents/skills/sprint-summary/fetch-sprint-issues.sh "<sprint-name>" > /tmp/sprint-issues-<sprint-name>.json
```

Use the same error handling as Mode: Summary (S2).

Collect all per-sprint JSON files for processing in the next step.

### T3. Compute statistics

For each sprint, read its JSON file and compute:

| Stat | Definition |
|---|---|
| Total tickets | Total number of issues |
| Tickets closed | `fields.status.name` in `["Done", "Closed", "Resolved"]` |
| Bugs closed | `fields.issuetype.name == "Bug"` AND status closed |
| Features/Stories delivered | `fields.issuetype.name` in `["Story", "Feature"]` AND status closed |

Also compute aggregate totals across all sprints.

### T4. Present the stats table

Display a markdown table:

```
Sprint Stats: <first-sprint> → <last-sprint>

| Sprint  | Total | Closed | Bugs Closed | Features Done |
|---------|-------|--------|-------------|---------------|
| 26.1.2  |  24   |   18   |      3      |       5       |
| 26.1.3  |  30   |   25   |      5      |       7       |
| 26.1.4  |  22   |   20   |      2      |       6       |
| **Total** | **76** | **63** | **10** | **18** |
```

### T5. Ask for follow-up

Ask the user:
- Any sprint to drill into for a full issue breakdown?
- Want to switch to Summary mode for one of these sprints?

---

## Rules

- Do not fabricate issue data — only use what comes from the Jira API response
- Keep output concise and scannable — tables and bullet points, not paragraphs
- If there are no issues in a category, omit that category header entirely
- If the fetch returns zero issues, tell the user and ask them to verify the sprint name
- In Stats mode, if a sprint fetch fails, skip it, note the failure, and continue with the rest
