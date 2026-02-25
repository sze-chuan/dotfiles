---
name: extract-sharing
description: Generates a structured knowledge-sharing note from a topic overview and reference links, then saves to Bear Notes. Use when the user wants to prepare a sharing or presentation on a topic and provides an overview and references.
user_invocable: true
---

# Extract Sharing

## Required Input

The user must provide:
- **Overview**: What the sharing is about, target audience, and any specific angle
- **References**: One or more URLs to source material

If either is missing, ask the user before proceeding.

## Workflow

### 1. Fetch reference material

Use WebFetch to retrieve and extract key content from all provided reference URLs. Extract the full structure, arguments, and examples from each source.

### 2. Synthesise into a sharing note

Combine the source material with the user's overview to produce a structured note. Adapt tone and depth to the stated audience.

Use this structure:

1. **What is it** — define the concept clearly for the audience
2. **Why it matters** — relevance to the target audience
3. **Core principles or habits** — 3–7 actionable takeaways, each with a heading and explanation
4. **Anti-patterns** — common mistakes as a table with columns: Anti-Pattern, What It Looks Like, What To Do Instead
5. **How to start practicing** — concrete, numbered next steps
6. **Key takeaway** — a memorable closing quote or statement
7. **References** — link back to all source articles

### 3. Save to Bear

Save the final note to Bear using `bear-create-note` with:
- **Title**: a concise, descriptive title for the sharing
- **Tags**: `sharing,engineering`

### 4. Confirm

Tell the user the note has been saved and is ready in Bear.

### 5. Create presentation (only when prompted)

Do NOT create a presentation by default. Only do this when the user explicitly asks (e.g., "create presentation", "make slides", "convert to marp").

Convert the sharing note into a Marp-format markdown presentation:
- Use the `~/repos/docs/Presentations/` folder, in a subfolder matching the topic (kebab-case)
- Follow the Marp frontmatter convention:
  ```
  ---
  marp: true
  style: |
    img[alt~="center"] {
      display: block;
      margin: 0 auto;
    }
  ---
  ```
- Split content into slides using `---` separators
- One key idea per slide — keep slides concise
- Use the same structure as the Bear note but adapted for presentation (shorter bullets, less prose)
- Include a title slide, a references slide at the end

## Rules

- Do not invent content — only synthesise what is in the references and the user's overview
- Keep language practical and direct, avoid corporate jargon
- Use markdown formatting (bold, blockquotes, tables) for readability
- If the audience is not specified, default to a general engineering audience
