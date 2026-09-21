---
name: acceptance-criteria
description: Generates user-facing acceptance criteria for testers based on the diff between the current branch and main, then appends the AC to the Jira ticket description. Use when the user asks to generate AC, acceptance criteria, or test criteria for their changes.
---

# Acceptance Criteria Generator

Generate clear, non-technical acceptance criteria for testers based on the changes introduced in the current branch compared to `main`, then append the AC to the linked Jira ticket.

## Prerequisites

- `JIRA_PAT` environment variable set with a valid Jira Personal Access Token
- Auto-loaded from `~/.env` if not already set in the environment

## Workflow

### 1. Gather branch context

Run these in parallel:
- `git branch --show-current` — get the current branch name
- `git log main...HEAD --oneline` — list commits on this branch
- `git diff main...HEAD --stat` — summarise files changed
- `git diff main...HEAD` — full diff to understand what changed

Extract the Jira ticket key from the branch name using:
```bash
git branch --show-current | grep -oE 'EDGEOS-[0-9]+'
```

If the command returns a key (e.g. `EDGEOS-1234`), use it for all subsequent Jira API calls.
If it returns nothing, ask the user: "I couldn't find a Jira ticket number in the branch name. What is the ticket key (e.g. EDGEOS-1234)?"

### 2. Understand the changes

Analyse the diff to identify:
- New UI elements or screens (buttons, forms, pages, modals, navigation)
- Changed user interactions or flows (form submission, navigation, actions)
- Removed functionality (features, options, fields that no longer exist)
- Changed behaviour (validation rules, error messages, success states, loading states)
- Permission or visibility changes (who can see or do what)
- Data display changes (labels, formatting, values shown to the user)

Focus on **what the user sees and does** — not on implementation details like function names, database queries, API endpoints, or internal logic.

### 3. Write acceptance criteria

Format the output as a numbered list of acceptance criteria. Each criterion must:
- Be written from the user's perspective ("The user can...", "When the user...", "The page should...")
- Describe observable behaviour — what a tester can verify by interacting with the UI or product
- Be specific enough to pass or fail definitively
- Avoid technical jargon (no function names, component names, API references, or code terms)

Group criteria by feature area or user flow if there are many changes.

**Output format:**

```
## Acceptance Criteria

### <Feature or flow name>

1. <Criterion>
2. <Criterion>
3. <Criterion>

### <Another feature or flow, if applicable>

4. <Criterion>
5. <Criterion>
```

If the branch only touches one area, skip the group headers and use a flat numbered list.

### 4. Add edge cases

After the main criteria, add an **Edge Cases** section covering:
- What happens when required fields are left blank (if forms are involved)
- Error states the user might encounter
- Boundary conditions visible to users (e.g. empty lists, maximum limits, long text)

Only include edge cases that are relevant to the changes — do not invent scenarios unrelated to the diff.

### 5. Ask for confirmation

Present the acceptance criteria to the user and ask:
- Are there any scenarios missing?
- Any criteria to reword or remove?

Apply any feedback and present the final version.

### 6. Fetch the current ticket description

Auto-load `~/.env` if `JIRA_PAT` is not set:
```bash
if [[ -z "${JIRA_PAT:-}" && -f "$HOME/.env" ]]; then
  set -a; source "$HOME/.env"; set +a
fi
```

Fetch the current issue to get its existing description:
```bash
JIRA_BASE_URL="${JIRA_BASE_URL:-https://jira.illumina.com}"

curl -s \
  -H "Authorization: Bearer ${JIRA_PAT}" \
  "${JIRA_BASE_URL}/rest/api/2/issue/<TICKET-KEY>?fields=description"
```

Extract and normalise the `fields.description` value from the response:
```bash
EXISTING_DESC=$(curl -s \
  -H "Authorization: Bearer ${JIRA_PAT}" \
  "${JIRA_BASE_URL}/rest/api/2/issue/<TICKET-KEY>?fields=description" \
  | jq -r '.fields.description // ""' \
  | tr -d '\r')
```

Using `jq -r` interprets JSON escape sequences into real characters, and `tr -d '\r'` removes any carriage returns (`\r`) so they are not stored back as literal `\r\n` sequences in the updated description.

If `EXISTING_DESC` is empty, the ticket has no description yet.

### 7. Append AC to the ticket description

Build the updated description by appending the AC block to the existing description. If `EXISTING_DESC` is empty, use only the AC block.

Format the AC section to append as plain text (Jira uses its own wiki markup — use `h2.` for headings and `#` for numbered lists):

```
h2. Acceptance Criteria

<# Criterion one>
<# Criterion two>
...

h2. Edge Cases

<# Edge case one>
<# Edge case two>
```

If the existing description already contains an `h2. Acceptance Criteria` section, **replace** that section rather than appending a duplicate.

Then update the ticket via the Jira API:
```bash
curl -s -o /tmp/jira-update-response.json -w "%{http_code}" \
  -X PUT \
  -H "Authorization: Bearer ${JIRA_PAT}" \
  -H "Content-Type: application/json" \
  -d "{\"fields\": {\"description\": \"<escaped-description>\"}}" \
  "${JIRA_BASE_URL}/rest/api/2/issue/<TICKET-KEY>"
```

Use `jq` to safely construct the JSON payload and escape the description string:
```bash
jq -n --arg desc "<full updated description>" '{"fields": {"description": $desc}}'
```

### 8. Confirm success

- If the HTTP response code is `204`, report success and show the ticket URL:
  `${JIRA_BASE_URL}/browse/<TICKET-KEY>`
- If the response is not `204`, show the HTTP code and response body, and tell the user the update failed without modifying any local files.

## Rules

- Write for **testers**, not developers — assume the reader has no access to the codebase
- Do not mention file names, component names, function names, or technical implementation
- Do not fabricate behaviour — only describe what is evident from the diff
- If the diff is empty or only contains non-user-facing changes (e.g. config, tests, comments), say so and ask the user to describe the intended behaviour instead
- Keep each criterion to one sentence where possible
- Use plain, direct language
- Always confirm the final AC with the user before writing to Jira — never update the ticket without user approval
- Never overwrite the full description; always preserve existing content and only add/replace the AC section
