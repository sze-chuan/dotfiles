#!/usr/bin/env bash
# Fetch all issues for a Jira sprint via REST API.
# Usage: fetch-sprint-issues.sh "26.1.4"  (resolves to full sprint name via board API)
#        fetch-sprint-issues.sh "EdgeOS 26.1.4 (02/16-02/27)"  (uses as-is)
#
# Environment variables:
#   JIRA_PAT       (required) — Personal Access Token for Bearer auth
#   JIRA_BASE_URL  (optional) — Jira server URL (default: https://jira.illumina.com)
#   JIRA_BOARD_ID  (optional) — Board ID (default: 4329)
#   JIRA_TEAM_ID   (optional) — Team custom field value (default: 317)
#
# Exit codes: 0=success, 1=missing args, 2=missing PAT, 3=API error

set -euo pipefail

# Auto-load ~/.env if JIRA_PAT is not already set
if [[ -z "${JIRA_PAT:-}" && -f "$HOME/.env" ]]; then
  set -a
  # shellcheck source=/dev/null
  source "$HOME/.env"
  set +a
fi

JIRA_BASE_URL="${JIRA_BASE_URL:-https://jira.illumina.com}"
JIRA_BOARD_ID="${JIRA_BOARD_ID:-4329}"
JIRA_TEAM_ID="${JIRA_TEAM_ID:-317}"

SPRINT_INPUT="${1:-}"
if [[ -z "$SPRINT_INPUT" ]]; then
  echo "Usage: $(basename "$0") <sprint-name>" >&2
  echo "Example: $(basename "$0") \"26.1.4\"" >&2
  exit 1
fi

if [[ -z "${JIRA_PAT:-}" ]]; then
  echo "Error: JIRA_PAT environment variable is not set." >&2
  echo "Export your Jira Personal Access Token before running this script." >&2
  exit 2
fi

TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT

# Resolve short sprint name (e.g. "26.1.4") to full name via board API
SPRINT_NAME="$SPRINT_INPUT"
if [[ "$SPRINT_INPUT" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Resolving sprint name for: ${SPRINT_INPUT}" >&2
  SPRINT_NAME=""
  START_AT_SPRINT=0
  while true; do
    SPRINTS_URL="${JIRA_BASE_URL}/rest/agile/1.0/board/${JIRA_BOARD_ID}/sprint?state=active,future,closed&maxResults=100&startAt=${START_AT_SPRINT}"
    HTTP_CODE=$(curl -s -w "%{http_code}" -o "$TMPFILE" \
      -H "Authorization: Bearer ${JIRA_PAT}" \
      "$SPRINTS_URL")

    if [[ "$HTTP_CODE" -lt 200 || "$HTTP_CODE" -ge 300 ]]; then
      echo "Error: Failed to list board sprints (HTTP ${HTTP_CODE})" >&2
      exit 3
    fi

    SPRINT_NAME=$(jq -r --arg q "$SPRINT_INPUT" '.values[] | select(.name | contains($q)) | .name' "$TMPFILE" | head -1)
    if [[ -n "$SPRINT_NAME" ]]; then
      break
    fi

    IS_LAST=$(jq -r '.isLast' "$TMPFILE")
    RETURNED_SPRINTS=$(jq -r '.values | length' "$TMPFILE")
    START_AT_SPRINT=$((START_AT_SPRINT + RETURNED_SPRINTS))
    if [[ "$IS_LAST" == "true" ]]; then
      break
    fi
  done

  if [[ -z "$SPRINT_NAME" ]]; then
    echo "Error: No sprint found matching \"${SPRINT_INPUT}\"" >&2
    exit 3
  fi
  echo "Resolved to: ${SPRINT_NAME}" >&2
fi

SEARCH_URL="${JIRA_BASE_URL}/rest/api/2/search"
JQL="sprint = \"${SPRINT_NAME}\" AND cf[20002] = ${JIRA_TEAM_ID}"
FIELDS="key,summary,issuetype,status,priority,assignee,labels,issuelinks"
PAGE_SIZE=50

ALL_ISSUES="[]"
START_AT=0

echo "Fetching issues for sprint: ${SPRINT_NAME}" >&2
echo "JQL: ${JQL}" >&2

while true; do
  PAYLOAD=$(jq -n \
    --arg jql "$JQL" \
    --argjson startAt "$START_AT" \
    --argjson maxResults "$PAGE_SIZE" \
    '{jql: $jql, startAt: $startAt, maxResults: $maxResults, fields: ["key","summary","issuetype","status","priority","assignee","labels","issuelinks","customfield_10006"]}'
  )

  HTTP_CODE=$(curl -s -w "%{http_code}" -o "$TMPFILE" \
    -X POST \
    -H "Authorization: Bearer ${JIRA_PAT}" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD" \
    "$SEARCH_URL")

  if [[ "$HTTP_CODE" -lt 200 || "$HTTP_CODE" -ge 300 ]]; then
    echo "Error: Jira API returned HTTP ${HTTP_CODE}" >&2
    echo "Response:" >&2
    cat "$TMPFILE" >&2
    exit 3
  fi

  TOTAL=$(jq -r '.total' "$TMPFILE")
  RETURNED=$(jq -r '.issues | length' "$TMPFILE")
  PAGE_ISSUES=$(jq '.issues' "$TMPFILE")

  # Merge page into accumulated results
  ALL_ISSUES=$(echo "$ALL_ISSUES" "$PAGE_ISSUES" | jq -s '.[0] + .[1]')

  FETCHED=$((START_AT + RETURNED))
  echo "Fetched ${FETCHED}/${TOTAL} issues..." >&2

  if [[ "$FETCHED" -ge "$TOTAL" ]]; then
    break
  fi

  START_AT=$FETCHED
done

# Resolve epic names from epic keys
EPIC_KEYS=$(echo "$ALL_ISSUES" | jq -r '[.[].fields.customfield_10006 // empty] | unique | .[]')

if [[ -n "$EPIC_KEYS" ]]; then
  echo "Resolving epic names..." >&2
  EPIC_JQL="key in ($(echo "$EPIC_KEYS" | paste -sd, -))"
  EPIC_PAYLOAD=$(jq -n --arg jql "$EPIC_JQL" '{jql: $jql, maxResults: 100, fields: ["summary"]}')

  HTTP_CODE=$(curl -s -w "%{http_code}" -o "$TMPFILE" \
    -X POST \
    -H "Authorization: Bearer ${JIRA_PAT}" \
    -H "Content-Type: application/json" \
    -d "$EPIC_PAYLOAD" \
    "$SEARCH_URL")

  if [[ "$HTTP_CODE" -ge 200 && "$HTTP_CODE" -lt 300 ]]; then
    EPIC_MAP=$(jq '[.issues[] | {(.key): .fields.summary}] | add // {}' "$TMPFILE")
    # Inject epicName into each issue based on its epic key
    ALL_ISSUES=$(echo "$ALL_ISSUES" | jq --argjson epics "$EPIC_MAP" '
      [.[] | .fields.epicName = (if .fields.customfield_10006 then $epics[.fields.customfield_10006] else null end)]
    ')
    echo "Resolved $(echo "$EPIC_MAP" | jq 'length') epic names." >&2
  else
    echo "Warning: Failed to resolve epic names (HTTP ${HTTP_CODE}), continuing without them." >&2
  fi
fi

echo "Done. ${TOTAL} issues fetched." >&2
echo "$ALL_ISSUES"
