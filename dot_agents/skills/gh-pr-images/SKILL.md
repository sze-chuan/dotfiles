---
name: gh-pr-images
description: >-
  Upload local screenshots into a GitHub or GitHub Enterprise pull request
  description so they render as user-attachments. Use when a PR needs images,
  gh cannot upload attachments (especially git.illumina.com), the pull-request
  skill says to use a signed-in browser, or the user asks to attach, upload,
  or embed screenshots on a pull request. Use this instead of leaving /tmp or
  local file paths in the PR body.
---

# Upload images to a GitHub pull request

`gh` can edit a pull request body, but on `git.illumina.com` its token cannot create `user-attachments` image URLs. GitHub only mints those URLs when a browser session that is already signed in uploads the file through the pull request description editor.

This is the path that worked. Do not commit the images. Do not print cookies, the keyring secret, `GitHub-Remote-Auth`, `Authorization` headers, or upload-policy JSON.

## Browser session

Load agent-browser core before the first browser command (`agent-browser skills get core`). Use a named session for every command in this task, including the cookie script:

```bash
export AGENT_BROWSER_SESSION="$(agent-browser session id --scope worktree --prefix gh-pr-images)"
agent-browser open "https://<host>/<owner>/<repo>/pull/<number>"
```

If the page is already the pull request, skip cookie import. A fresh agent-browser profile is not signed in. Do not point `--profile` at the live Chromium directory; that profile is locked while Chromium is open.

## Sign in from the existing Chromium session

When the page is the GitHub login screen, copy only that host's cookies from `~/.config/chromium/Default/Cookies` into this session:

```bash
node ~/.agents/skills/gh-pr-images/scripts/import-github-cookies.mjs --host git.illumina.com
agent-browser open "https://<host>/<owner>/<repo>/pull/<number>"
```

The script is the decryption that worked on this machine: `secret-tool lookup application chromium`, PBKDF2-HMAC-SHA1 (`saltysalt`, 1 iteration, 16 bytes), AES-128-CBC with an IV of 16 spaces, then a 32-byte prefix stripped only when the plaintext is not text. It prints cookie names and `set`/`fail`. `--check` confirms decryption without calling agent-browser.

Reopen the pull request after the cookies are set. Stop if it is still a login page.

## Upload into the description

The images belong in the opening comment (the PR body), not a new comment. The accessibility menu on that comment often shows only "Quote reply". The edit control is still the first `.js-comment-edit-button` in the DOM.

`agent-browser eval` keeps a persistent JavaScript realm. Wrap every expression in an IIFE so later evals do not redeclare `const`.

```bash
agent-browser eval "(() => { document.querySelector('.js-comment-edit-button').click(); return 'editing'; })()"
```

After the editor opens, the description's file input is `input[type=file][id^="fc-issue-"]`. Leave `#fc-new_comment_field` alone; that input belongs to the new-comment box.

```bash
agent-browser upload "#fc-issue-<id>-body" /path/one.png /path/two.png
```

Upload each file once. A second upload appends another copy. `upload` returns before GitHub finishes. The editor textarea id is the file-input id without the `fc-` prefix (`#issue-<id>-body`). Wait until that textarea contains one `<img ... src="https://<host>/user-attachments/assets/...">` per file. GitHub inserts HTML image tags, not Markdown image syntax. Do not scrape the `/upload/policies/assets` response; it contains a remote auth token.

## Keep one image per shot

Replace the Screenshots section (or add one) so each image has a caption and the local paths are gone. Set the textarea value in the page, then dispatch `input` and `change`, or GitHub saves the previous text.

```bash
agent-browser eval "(() => {
  const area = document.querySelector('#issue-<id>-body');
  const shots = \`# Screenshots
After:

**What this shot shows.**

<img width=\"768\" alt=\"short description\" src=\"https://<host>/user-attachments/assets/<uuid>\" />

\`;
  const text = area.value.replace(/<img[^>]*\\/>\\n?/g, '');
  const start = text.indexOf('# Screenshots');
  const end = text.indexOf('# AI Prompt');
  area.value = text.slice(0, start) + shots + text.slice(end);
  area.dispatchEvent(new Event('input', { bubbles: true }));
  area.dispatchEvent(new Event('change', { bubbles: true }));
  return (area.value.match(/<img/g) || []).length;
})()"
```

Adjust the end marker to the next real heading when the body has no `# AI Prompt` section. Then click **Update comment**.

## Confirm

Reload the pull request. Each inserted image should have `complete === true` and `naturalWidth > 0`. `gh pr view` should show `user-attachments` URLs and no local paths.

Close the browser when finished (`agent-browser close`). If the upload still fails, say so in the Screenshots section and leave the files only on the machine.
