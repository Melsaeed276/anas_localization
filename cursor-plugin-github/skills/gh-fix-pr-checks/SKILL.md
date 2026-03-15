---
name: gh-fix-pr-checks
description: Debug or fix failing GitHub PR checks that run in GitHub Actions — inspect checks and logs, detect failure patterns (flaky/timeout/OOM), draft a fix plan, and implement only after explicit approval. Parse workflow YAML for job dependencies and suggest re-running only failed jobs. Treat non–GitHub Actions providers as out of scope.
---

# gh Fix PR Checks

Debug failing GitHub Actions checks on a PR: inspect logs, detect failure patterns, create a targeted fix plan, and implement after approval.

## When to Use

- User says "fix failing CI", "my PR checks are failing", "fix the build"
- User wants to understand why a CI job failed
- User wants to re-run only the failed jobs

## Prerequisites

- `gh` installed and authenticated with `workflow` scope (`gh auth status`).
- Must be inside the repo with the failing PR.

## Instructions

### Step 1 — Resolve the PR

```bash
gh pr view --json number,url,headRefName
```

If the user specified a PR number or URL, use that instead.

### Step 2 — List failing checks

```bash
gh pr checks
```

For each failing check:
- Note the check name and `detailsUrl`.
- If `detailsUrl` is NOT a GitHub Actions URL (e.g. Buildkite, CircleCI), label it as **external**, output the URL only, and skip further debugging for it.
- For GitHub Actions URLs, extract the run ID from the URL path.

### Step 3 — Parse workflow YAML for job dependencies

```bash
ls .github/workflows/*.yml
```

For each failing workflow file, read the `jobs:` section:
- Identify `needs:` dependencies between jobs.
- If a job failed because an upstream `needs` job failed, note the root cause job and focus debugging there.
- Use this to suggest re-running only the root-cause job when possible.

### Step 4 — Fetch and analyse logs

```bash
# Get run summary
gh run view <run_id> --json name,conclusion,status,url,jobs

# Fetch full log for the failing job
gh run view <run_id> --log | grep -A 20 "##\[error\]\|FAILED\|Error\|fatal"
```

If log is very large, use `scripts/inspect_pr_checks.py` (if present):
```bash
python scripts/inspect_pr_checks.py --repo . --pr <number>
```

### Step 5 — Detect failure patterns

From the log snippet, identify:

| Pattern | Signals | Suggested mitigation |
|---------|---------|----------------------|
| **Flaky test** | "Test passed on retry", "Flaky" | Re-run failed jobs; add retry logic to test |
| **Timeout** | "Job exceeded time limit", "timed out" | Increase `timeout-minutes` in workflow YAML |
| **OOM** | "Killed", "out of memory", "OOMKilled" | Increase runner memory; reduce parallelism |
| **Dependency/network** | "npm ERR! network", "could not resolve", "rate limit" | Retry; cache dependencies; check token scopes |
| **Lint/compile error** | "error:", "Compilation failed" | Fix the code issue in the log |

### Step 6 — Summarize

Present to the user:
```
Failing check: <name>
Run URL: <url>
Root cause job: <job> (upstream dep: <dep-job>)
Pattern detected: <pattern or "no pattern – code fix required">
Log snippet:
  <5–10 lines showing the error>
```

### Step 7 — Create fix plan

Draft a concise plan:
- For code errors: describe the file and change needed.
- For flaky tests: propose retry in workflow or fix test isolation.
- For timeout: show the YAML change to increase `timeout-minutes`.
- For OOM: show the YAML change to use a larger runner.
- For dependency errors: show cache or retry step to add.

**Ask the user: "Implement this fix? (yes/no)"**

### Step 8 — Implement after approval

Apply the approved changes. For code fixes: edit files. For YAML changes: edit `.github/workflows/<file>.yml`.

### Step 9 — Rerun checks

After fixing:
```bash
# Rerun only failed jobs (preferred)
gh run rerun <run_id> --failed

# Or re-run the whole workflow
gh run rerun <run_id>
```

## Validation

- `gh pr checks` shows all checks passing (✓) after fix.
- `gh run view <run_id>` conclusion is `success`.
- No new failures introduced.

## Error Handling

| Error | Next step |
|-------|-----------|
| `gh: not authenticated / missing workflow scope` | Run `gh auth login` with `workflow` scope |
| External CI (non-GitHub Actions) | Report URL only; do not attempt to debug |
| Log too large | Use `scripts/inspect_pr_checks.py` or `gh run view --log \| tail -n 200` |
| `--failed flag not supported` | Fall back to `gh run rerun <id>` (full rerun) |
| `rerun: permission denied` | Verify user has write access to repo Actions |
