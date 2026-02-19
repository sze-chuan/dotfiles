#!/usr/bin/env bash
# Fetch all issues for a Jira sprint via REST API.
# Usage: fetch-sprint-issues.sh "Sprint 26.1.4"
#
# Environment variables:
#   JIRA_PAT       (required) — Personal Access Token for Bearer auth
#   JIRA_BASE_URL  (optional) — Jira server URL (default: https://jira.illumina.com)
#   JIRA_BOARD_ID  (optional) — Board ID (default: 4329)
#   JIRA_TEAM_ID   (optional) — Team custom field value (default: 317)
#
# Exit codes: 0=success, 1=missing args, 2=missing PAT, 3=API error

set -euo pipefail

JIRA_BASE_URL="${JIRA_BASE_URL:-https://jira.illumina.com}"
JIRA_BOARD_ID="${JIRA_BOARD_ID:-4329}"
JIRA_TEAM_ID="${JIRA_TEAM_ID:-317}"

SPRINT_NAME="${1:-}"
if [[ -z "$SPRINT_NAME" ]]; then
  echo "Usage: $(basename "$0") <sprint-name>" >&2
  echo "Example: $(basename "$0") \"Sprint 26.1.4\"" >&2
  exit 1
fi

if [[ -z "${JIRA_PAT:-}" ]]; then
  echo "Error: JIRA_PAT environment variable is not set." >&2
  echo "Export your Jira Personal Access Token before running this script." >&2
  exit 2
fi

TMPFILE=$(mktemp)
trap 'rm -f "$TMPFILE"' EXIT

SEARCH_URL="${JIRA_BASE_URL}/rest/api/2/search"
JQL="sprint = \"${SPRINT_NAME}\" AND cf[20002] = ${JIRA_TEAM_ID}"
FIELDS="key,summary,issuetype,status,priority,assignee,labels,issuelinks"
PAGE_SIZE=50

ALL_ISSUES="[]"
START_AT=0

echo "Fetching issues for sprint: ${SPRINT_NAME}" >&2
echo "JQL: ${JQL}" >&2

while true; do
  PAYLOAD=$(cat <<EOF
{
  "jql": "${JQL}",
  "startAt": ${START_AT},
  "maxResults": ${PAGE_SIZE},
  "fields": ["key","summary","issuetype","status","priority","assignee","labels","issuelinks"]
}
EOF
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

echo "Done. ${TOTAL} issues fetched." >&2
echo "$ALL_ISSUES"
