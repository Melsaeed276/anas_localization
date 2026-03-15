---
name: gh-actions-basics
description: Inspect and debug GitHub Actions runs and workflows using `gh run list`, `gh run view`, `gh run rerun`, and `gh workflow list`. Use when the user asks about Actions runs, workflow status, or wants to re-run jobs.
---

# gh Actions Basics

Inspect, debug, and re-run GitHub Actions workflows and runs.

## When to Use

- User asks "what are my recent CI runs?", "show me the workflow status"
- User wants to re-run a failed or cancelled workflow run
- User wants to list or enable/disable workflows
- Companion to `gh-fix-pr-checks` for lower-level Actions access

## Prerequisites

- `gh` installed and authenticated with `workflow` scope.
- Run `gh auth status` first.

## Instructions

### List recent runs

```bash
gh run list                              # recent runs for all workflows
gh run list --limit 20                   # more results
gh run list --branch <branch>            # runs for a specific branch
gh run list --status failure             # only failed runs
gh run list --workflow <filename>.yml    # runs for a specific workflow
gh run list --json databaseId,name,status,conclusion,url
```

### View a specific run

```bash
gh run view <run_id>                     # summary with job list
gh run view <run_id> --log               # full log output
gh run view <run_id> --log-failed        # logs for failed steps only
gh run view <run_id> --json name,jobs,conclusion,url
```

Get run ID from `gh run list` or from the `detailsUrl` in `gh pr checks`.

### View individual job logs

```bash
# Get job IDs
gh run view <run_id> --json jobs --jq '.jobs[] | {id: .databaseId, name, conclusion}'

# Fetch specific job logs via API
gh api repos/{owner}/{repo}/actions/jobs/<job_id>/logs
```

### Re-run a workflow

```bash
# Re-run only failed jobs (preferred — faster, cheaper)
gh run rerun <run_id> --failed

# Re-run all jobs in the workflow
gh run rerun <run_id>

# Re-run and enable debug logging
gh run rerun <run_id> --debug
```

### List and manage workflows

```bash
gh workflow list                         # list all workflows
gh workflow view <workflow-id>           # view details
gh workflow enable <workflow-id>         # enable a disabled workflow
gh workflow disable <workflow-id>        # disable a workflow
gh workflow run <workflow-id>            # manually trigger a workflow
```

### Watch a run in real time

```bash
gh run watch <run_id>                    # live status until completion
```

### Point to workflow YAML files

Workflow definitions live in `.github/workflows/*.yml`. Edit these files to:
- Change `timeout-minutes` for timeout issues
- Add `continue-on-error: true` for non-critical steps
- Add caching steps (`actions/cache`) for dependency speed
- Add `retry-step` logic for flaky tests

## Validation

- `gh run view <run_id>` shows `conclusion: success` after a successful rerun.
- `gh run list --status failure` shows fewer (or no) entries after fixing the issue.
- GitHub Actions tab in the repo shows green checks.

## Error Handling

| Error | Next step |
|-------|-----------|
| `workflow scope missing` | Re-authenticate: `gh auth login` and grant `workflow` scope |
| `run not found` | Verify run ID with `gh run list` |
| `--failed not supported` | Upgrade `gh`; fall back to full rerun |
| `manually trigger requires inputs` | Use `gh workflow run <id> --field key=value` |
