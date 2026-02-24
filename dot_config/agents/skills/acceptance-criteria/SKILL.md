---
name: acceptance-criteria
description: Generates user-facing acceptance criteria for testers based on the diff between the current branch and main. Use when the user asks to generate AC, acceptance criteria, or test criteria for their changes.
---

# Acceptance Criteria Generator

Generate clear, non-technical acceptance criteria for testers based on the changes introduced in the current branch compared to `main`.

## Workflow

### 1. Gather branch changes

Run these in parallel:
- `git log main...HEAD --oneline` — list commits on this branch
- `git diff main...HEAD --stat` — summarise files changed
- `git diff main...HEAD` — full diff to understand what changed

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

## Rules

- Write for **testers**, not developers — assume the reader has no access to the codebase
- Do not mention file names, component names, function names, or technical implementation
- Do not fabricate behaviour — only describe what is evident from the diff
- If the diff is empty or only contains non-user-facing changes (e.g. config, tests, comments), say so and ask the user to describe the intended behaviour instead
- Keep each criterion to one sentence where possible
- Use plain, direct language
