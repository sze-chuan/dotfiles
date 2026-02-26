---
name: raindrop
description: Manage Raindrop.io bookmarks — view, search, organise, edit, and delete. Use when the user wants to work with their Raindrop bookmarks or collections.
user_invocable: true
---

# Raindrop Bookmark Manager

Manage Raindrop.io bookmarks via the REST API. Supports four modes:
- **View** — browse or search bookmarks
- **Organize** — move bookmarks between collections or bulk-update tags
- **Edit** — update a bookmark's title, URL, tags, note, or collection
- **Delete** — remove one or more bookmarks

## Prerequisites

- `RAINDROP_TOKEN` environment variable set with a valid Raindrop API token
- Auto-loaded from `~/.env` if not already set:
  ```bash
  if [[ -z "${RAINDROP_TOKEN:-}" && -f "$HOME/.env" ]]; then
    set -a; source "$HOME/.env"; set +a
  fi
  ```
- `curl` and `jq` installed

## Constants

```
BASE_URL=https://api.raindrop.io/rest/v1
AUTH="Authorization: Bearer ${RAINDROP_TOKEN}"
```

Special collection IDs:
- `0` — All bookmarks
- `-1` — Unsorted
- `-99` — Trash

## Workflow

### 1. Select mode

Ask the user which mode they want:
- **View** — browse or search bookmarks
- **Organize** — move or bulk-tag bookmarks
- **Edit** — update a single bookmark
- **Delete** — delete one or more bookmarks

Then follow the corresponding workflow below.

---

## Mode: View

### V1. Ask what to show

Ask the user:
- Do they want to search by keyword, or browse a collection?
- If browsing: which collection? (offer: All, Unsorted, or enter a name)
- How many results? (default: 25)

### V2. Resolve collection ID

If the user chose a named collection (not All/Unsorted), fetch the list:

```bash
curl -s -H "$AUTH" "${BASE_URL}/collections" | jq '.items[] | {id, title}'
curl -s -H "$AUTH" "${BASE_URL}/collections/childrens" | jq '.items[] | {id, title}'
```

Match the user's input against `title` (case-insensitive). If multiple matches, ask the user to clarify.

| User choice | collectionId |
|---|---|
| All | `0` |
| Unsorted | `-1` |
| Trash | `-99` |
| Named collection | resolved `id` |

### V3. Fetch bookmarks

```bash
curl -s -H "$AUTH" \
  "${BASE_URL}/raindrops/${COLLECTION_ID}?perpage=${PERPAGE}&page=0${SEARCH_PARAM}" \
  | jq '.items[] | {id, title, link, tags, excerpt, collectionId: .collection.$id}'
```

Where `SEARCH_PARAM` is `&search=<keyword>` if the user provided a keyword.

Sort options (ask if user wants to sort): `title`, `-title`, `domain`, `-domain`, `-date` (newest first), `date` (oldest first). Default: `-1` (by position).

Add `&sort=<value>` to the URL when specified.

### V4. Display results

Show a numbered table:

```
#  | Title                        | Domain          | Tags           | ID
---|------------------------------|-----------------|----------------|----------
1  | My Bookmark Title            | example.com     | dev, tools     | 12345678
2  | Another Bookmark             | github.com      | oss            | 87654321
```

Show total count from `result.count`. If there are more pages, tell the user and offer to fetch the next page (`&page=1`, `&page=2`, etc.).

### V5. Offer follow-up

After displaying results, ask:
- Open a bookmark URL?
- Switch to Edit or Delete mode for any listed item?
- Refine the search?

---

## Mode: Organize

### O1. Ask what to organise

Ask the user:
- Move specific bookmarks to a different collection?
- Bulk-add or remove tags from a set of bookmarks?

### O2. Identify target bookmarks

If moving/tagging specific items:
- Ask the user for bookmark IDs or a search query to identify them
- If search: run V2–V4 to show matches and let the user confirm which ones

If bulk-updating by collection:
- Ask which collection to operate on
- Resolve the collection ID (see V2)

### O3. Execute the operation

**Move to collection:**
```bash
curl -s -X PUT -H "$AUTH" -H "Content-Type: application/json" \
  -d "{\"ids\": [${IDS}], \"collection\": {\"\$id\": ${TARGET_COLLECTION_ID}}}" \
  "${BASE_URL}/raindrops/${SOURCE_COLLECTION_ID}"
```

**Bulk add tags:**
```bash
curl -s -X PUT -H "$AUTH" -H "Content-Type: application/json" \
  -d "{\"ids\": [${IDS}], \"tags\": [\"${TAG1}\", \"${TAG2}\"]}" \
  "${BASE_URL}/raindrops/${COLLECTION_ID}"
```

Note: bulk tag update **replaces** all existing tags on the affected bookmarks. Warn the user before proceeding if they are adding tags (they may want to retrieve existing tags first and merge).

### O4. Confirm result

Report how many bookmarks were updated. If the API returns an error, show the response body and ask the user how to proceed.

---

## Mode: Edit

### E1. Identify bookmark

Ask the user for the bookmark ID, or a title/URL to search for.

If searching:
```bash
curl -s -H "$AUTH" \
  "${BASE_URL}/raindrops/0?search=<query>&perpage=10" \
  | jq '.items[] | {id, title, link}'
```

Show matches and ask the user to confirm which one to edit.

### E2. Fetch current values

```bash
curl -s -H "$AUTH" "${BASE_URL}/raindrop/${ID}" \
  | jq '.item | {id, title, link, tags, note, excerpt, collection: .collection.$id}'
```

Display the current values to the user.

### E3. Ask what to change

Ask which fields to update:
- `title` — display name
- `link` — URL
- `tags` — array of strings (replaces existing tags)
- `note` — personal note
- `excerpt` — description/excerpt
- `collection.$id` — move to a different collection (resolve name → ID as in V2)
- `important` — mark as favourite (true/false)

### E4. Apply the update

Build the JSON body with only the changed fields:

```bash
curl -s -X PUT -H "$AUTH" -H "Content-Type: application/json" \
  -d "${JSON_BODY}" \
  "${BASE_URL}/raindrop/${ID}"
```

Use `jq -n` to safely construct the payload:
```bash
jq -n --arg title "${TITLE}" --argjson tags "${TAGS_JSON}" \
  '{"title": $title, "tags": $tags}'
```

### E5. Confirm result

Show the updated bookmark fields. If the API returns an error, display the response and ask the user how to proceed.

---

## Mode: Delete

### D1. Identify bookmarks

Ask the user:
- Delete a single bookmark by ID?
- Delete multiple by ID list?
- Delete by search query within a collection?
- Empty the Trash?

### D2. Confirm deletion

Before deleting, always show the bookmark title(s) and ask for confirmation:

```
About to delete:
  - [12345678] My Bookmark Title (example.com)
  - [87654321] Another Bookmark (github.com)

Deleted bookmarks are moved to Trash. Proceed? (y/n)
```

For **Empty Trash**, warn: "This will permanently delete all bookmarks in Trash. This cannot be undone."

### D3. Execute deletion

**Single bookmark:**
```bash
curl -s -X DELETE -H "$AUTH" "${BASE_URL}/raindrop/${ID}"
```

**Multiple bookmarks** (specify collection context; use `0` for all):
```bash
curl -s -X DELETE -H "$AUTH" -H "Content-Type: application/json" \
  -d "{\"ids\": [${IDS}]}" \
  "${BASE_URL}/raindrops/${COLLECTION_ID}"
```

**Empty Trash:**
```bash
curl -s -X DELETE -H "$AUTH" "${BASE_URL}/collection/-99"
```

**Note:** Deleting from any collection except `-99` moves bookmarks to Trash. Deleting from `-99` permanently removes them.

### D4. Confirm result

Report how many bookmarks were deleted (or trashed). If the API returns an error, show the response body.

---

## Rules

- Always load `RAINDROP_TOKEN` from `~/.env` if not set in the environment
- Never fabricate bookmark data — only show what comes from the API
- Always confirm before deleting — show titles, not just IDs
- Warn users when bulk tag updates will replace existing tags
- Rate limit: 120 requests/minute — avoid unnecessary calls; batch where possible
- If the API returns an error, show the HTTP status and response body; do not silently fail
- Keep output scannable — use tables and bullet lists, not paragraphs
- When IDs are needed, always prefer resolving from names/searches rather than asking the user to look them up manually
