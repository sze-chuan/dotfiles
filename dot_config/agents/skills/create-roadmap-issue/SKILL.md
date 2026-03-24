---
name: create-roadmap-issue
description: Creates a GitHub roadmap issue in ui-ninjas-playbook by reading a Jira ticket description and filling in the initiative template (Context, Intended outcome, Proposed scope). Use when the user wants to create a roadmap issue or initiative from a Jira ticket.
---

# Create Roadmap Issue

Read a Jira ticket and create a GitHub issue in `ui-ninjas-playbook` using the initiative template.

## Prerequisites

- `JIRA_PAT` environment variable set with a valid Jira Personal Access Token
- Auto-loaded from `~/.env` if not already set in the environment
- `gh` CLI installed and authenticated
- `jq` installed

## Workflow

### 1. Get the Jira ticket key

If the user provided a ticket key (e.g. `EDGEOS-1234`), use it.
If not, ask: "What is the Jira ticket key for this initiative? (e.g. EDGEOS-1234)"

### 2. Fetch the Jira ticket

Auto-load `~/.env` if `JIRA_PAT` is not set:
```bash
if [[ -z "${JIRA_PAT:-}" && -f "$HOME/.env" ]]; then
  set -a; source "$HOME/.env"; set +a
fi
```

Fetch the ticket's summary and description:
```bash
JIRA_BASE_URL="${JIRA_BASE_URL:-https://jira.illumina.com}"

curl -s \
  -H "Authorization: Bearer ${JIRA_PAT}" \
  "${JIRA_BASE_URL}/rest/api/2/issue/<TICKET-KEY>?fields=summary,description"
```

Extract fields:
```bash
TICKET_DATA=$(curl -s \
  -H "Authorization: Bearer ${JIRA_PAT}" \
  "${JIRA_BASE_URL}/rest/api/2/issue/<TICKET-KEY>?fields=summary,description")

SUMMARY=$(echo "$TICKET_DATA" | jq -r '.fields.summary // ""')
DESCRIPTION=$(echo "$TICKET_DATA" | jq -r '.fields.description // ""')
```

If the API returns an error or both fields are empty, show the response and ask the user to verify the ticket key.

### 3. Map ticket content to the initiative template

The GitHub issue template has three sections:

```markdown
### Context
Provide context of this initiative.

### Intended outcome
Provide outcome of this initiative.

### Proposed scope
Provide scope of this initiative.
```

Analyse the ticket summary and description to populate each section:

- **Context**: Background information, problem statement, motivation, or "why" behind the initiative. Look for sections labelled "Background", "Problem", "Context", "Why", or introductory paragraphs.
- **Intended outcome**: Goals, success criteria, expected results, or desired end state. Look for sections labelled "Goal", "Outcome", "Success criteria", "Expected result", or "Objective".
- **Proposed scope**: What is in scope, deliverables, features to build, or work to be done. Look for sections labelled "Scope", "Deliverables", "Acceptance criteria", "In scope", or detailed feature lists.

If the description is sparse or a section cannot be clearly inferred, use a brief placeholder based on the summary and note to the user that it needs filling in.

### 4. Draft the issue body

Build the issue body using the template structure:

```markdown
### Context
<mapped content>

### Intended outcome
<mapped content>

### Proposed scope
<mapped content>
```

### 5. Present draft to user

Show the user:
- Proposed issue **title**: `<ticket summary>`
- Proposed issue **body**: the populated template

Ask:
- Does the content look correct?
- Any sections to update before creating?

Apply any feedback before proceeding.

### 6. Create the GitHub issue

Once the user confirms, create the issue:

```bash
gh issue create \
  --repo illumina/ui-ninjas-playbook \
  --title "<summary>" \
  --body "$(cat <<'EOF'
<populated body>
EOF
)" \
  --label "roadmap"
```

If the `roadmap` label does not exist in the repo, omit `--label` and note this to the user.

### 7. Return the issue URL

Output the created issue URL so the user can review it.

## Rules

- Never create the issue without user confirmation of the draft content
- Do not fabricate content — only use what is present in the Jira ticket
- If a section cannot be inferred from the ticket, use a clear placeholder (e.g. `_To be defined_`) rather than guessing
- Keep each section concise — bullet points are preferred over long paragraphs
- The issue title must not include the Jira ticket key
