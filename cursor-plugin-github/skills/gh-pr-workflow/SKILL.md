---
name: gh-pr-workflow
description: Navigate and inspect pull requests with the GitHub CLI — view PR for the current branch, list checks, open in browser, view diff. Use when the user asks about PR status, checks, what's on the current PR, or wants to see open PRs.
---

# gh PR Workflow

Navigate and inspect GitHub pull requests using the `gh` CLI.

## When to Use

- User asks "what's the status of my PR?"
- User wants to see check results (CI/CD pass/fail)
- User wants to view the PR diff or open it in a browser
- User wants to list open PRs or find a specific PR

## Prerequisites

- `gh` installed and authenticated (`gh auth status` must succeed).
- Rule `gh-auth-first` is always active; verify auth before any command.

## Instructions

### 1. View the current branch's PR

```bash
gh pr view                          # summary in terminal
gh pr view --web                    # open in browser
gh pr view --json number,url,title,state,headRefName
```

### 2. List PR checks / CI status

```bash
gh pr checks                        # all checks for current PR
gh pr checks --watch                # live update until all checks finish
```

### 3. View the diff

```bash
gh pr diff                          # patch diff in terminal
gh pr diff --web                    # open Files Changed tab in browser
```

### 4. List PRs across the repo

```bash
gh pr list                          # open PRs
gh pr list --state all              # all PRs
gh pr list --author @me             # my PRs only
gh pr list --label bug              # filter by label
gh pr list --json number,title,state,url   # machine-readable
```

### 5. View a specific PR by number

```bash
gh pr view 42
gh pr view 42 --json number,title,reviews,statusCheckRollup
```

## Common Options

| Flag | Effect |
|------|--------|
| `--json <fields>` | Return structured JSON (combine with `--jq` to filter) |
| `--jq <expr>` | Filter JSON output with jq expression |
| `--web` | Open in default browser |
| `--watch` | Poll until checks complete |

## Validation

After running `gh pr view`:
- Output shows the PR title, number, branch, and state (open/merged/closed).
- `gh pr checks` shows each check name with status (pass ✓ / fail ✗ / pending).
- If checks are failing, proceed with the `gh-fix-pr-checks` skill.
