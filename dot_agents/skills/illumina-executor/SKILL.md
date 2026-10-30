---
name: illumina-executor
description: Use Executor for Illumina Jira and Confluence, EdgeOS Jenkins, and for GitHub Enterprise when gh is a poor fit. Use gh for github.com — Executor is not configured for public GitHub. Use when the task involves git.illumina.com, jira.illumina.com, confluence.illumina.com, jenkins.edgeos.illumina.com, github.com, Illumina tickets, wiki pages, CI jobs, or GHE repos.
---

# Illumina internal tools

Do not use the Atlassian plugin or raw curl/REST to these hosts.

| Host | Default |
|---|---|
| `jira.illumina.com` | Executor `jira` |
| `confluence.illumina.com` | Executor `confluence` |
| `jenkins.edgeos.illumina.com` | Executor `edgeos-jenkins` |
| `git.illumina.com` | `gh` in a local clone; otherwise Executor `github-enterprise` |
| `github.com` | `gh` only. Executor has no public GitHub connection. |

**`gh`** for github.com always, and for a GHE repo you already have (or are cloning): PRs, checks, reviews, issue CRUD. For GHE, set `GH_HOST=git.illumina.com` if the remote is not already that host.

**Executor** for Jira, Confluence, EdgeOS Jenkins (`jenkins.edgeos.illumina.com`), GHE search or files outside the current clone, and any task that spans those systems. Never point Executor at github.com.

Before writing Executor `execute` code, load `skills({ name: "execute" })`. If Executor is unavailable or an integration is missing, say so and stop unless the user asks for a fallback.
