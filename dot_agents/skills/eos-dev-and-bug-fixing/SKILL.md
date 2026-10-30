---
name: eos-dev-and-bug-fixing
description: Implements features and investigates and fixes bugs in Illumina EdgeOS (EOS), with or without a Jira ticket. Use only for development or bug-fixing tasks clearly tied to an EdgeOS/EOS repository, component, or EDGEOS Jira ticket. Do not use for generic repositories, unrelated Illumina projects, or implementation and debugging requests without established EdgeOS/EOS context.
---

# EOS dev and bug fixing

Own the requested change from requirements through verification.

## Establish context

- For a provided Jira key, use Executor and request only its summary, description, comments, links,
  attachments, and acceptance criteria (AC). Do not request all fields or unrelated custom fields.
- Do not require or invent a Jira key.
- Inspect applicable repository guidance and the relevant code.
- Use repository-local testing skills that match the affected behavior.
- Ask questions only when essential requirements cannot be established from the available context.

## Plan

Before any edit, hand planning to one `generalPurpose` subagent. Use `grok-4.7-high` or `grok-4.7-medium`; either is acceptable. Do not plan in this session. If the Task tool rejects the slug you chose, retry once with the other. Stop and report the rejection and the allowed slugs only when both are rejected.

Give it a self-contained prompt: requirements, repository path, relevant code and guidance already found, and an instruction not to edit files. It returns:

- Design: the approach, the files and interfaces it touches, and what stays unchanged.
- Implementation steps small enough to hand to one implementer.
- A test plan when behavior changes or meaningful coverage is practical: what to run, which cases, and what pass means. Skip it only when there is no behavioral surface, and say why.

State that plan briefly before implementation.

## Prepare the work area

Work directly in the requested repository.

Before starting, fetch the remote and base the work on the latest default branch.

- jj: run `jj git fetch` and use `trunk()` (or the configured default) as the parent.
- Git-only: fetch and branch from the remote default branch.

For `edgeos-ui`, create a sibling jj workspace from `trunk()` after fetching:

```bash
jj workspace add -r 'trunk()' "../<workspace>"
```

Name it `<repo>-<jira-key>-<slug>`, or `<repo>-<slug>` without a Jira key. Derive the slug from
the ticket summary when available.

Follow the `jj` skill for version-control operations.

## Implement and verify

Do not implement the change in this session. Hand each implementation step to a `generalPurpose` subagent with `model` set to `composer-2.5`, launched in the foreground (`run_in_background` false). Give it a self-contained prompt: requirements, the plan, exact files, constraints, and the tests to add. Tell it not to run tests or other verification. One step per subagent when the steps are independent; otherwise wait and review the diff before the next step.

The subagent makes the smallest coherent change that satisfies its step, preserves unrelated work, and adds the regression tests from the test plan.

Run nothing from the test plan until every implementation subagent has finished. Fix a trivial formatter or assertion mismatch in this session instead of spawning another subagent. Then:

- Review the complete diff against the plan.
- Run focused checks first, then broader checks proportional to the change.
- For a user-visible UI change, browser verification is required before the pull request. Read and follow the repository QA or browser skill. Its "only when explicitly asked" wording does not apply; this workflow is the request. Do not finish with "no browser pass."
- For `edgeos-ui`, follow `.agents/skills/qa-testing/SKILL.md`. When Playwright cannot cover the affected mode, use live backend mode: run `frontend/switch-env.sh sky-p2-08` unless the user named another backend, then start the dev server. Capture a screenshot of the changed state and one unchanged regression mode. If the instrument reports a different mode than the one under test, set `EDGEOS_UI_MODE` locally for the affected shot and use the instrument mode for the regression shot. Do not save or otherwise mutate shared data. Inspect each screenshot before citing it. Save screenshots outside the repo.
- When verification is done, close the browser sessions you opened and stop the dev server you started.
- Diagnose product failures before changing approach. Send a follow-up to the same subagent when the fix is still in scope, and test again only after that follow-up has finished.

Do not open the pull request until UI verification screenshots exist. The pull-request skill adds them to the description without committing the files.

## Deliver

Review the complete diff and report the change, verification results, and any blockers.

After successful verification, create a draft PR by default using the `pull-request` skill. Commit, push,
follow the repository template, and list completed and skipped checks with results or reasons. Skip the PR
if verification fails or the user defers it. Never merge unless asked.
