---
name: gh-fix-ci
description: Debug and fix failing GitHub Actions checks on the current (or given) PR — inspect logs, detect failure patterns, propose a fix plan, and implement only after explicit approval.
---

# Fix CI Checks

## Applies to
files: ["*"]

## Command

Debug failing GitHub Actions checks and fix the root cause.

Steps:

1. **Verify `gh` auth**
   Run `gh auth status`. Confirm `workflow` scope is present. If not, ask user to run `gh auth login` and re-grant scopes.
   Check `gh --version`; if outdated, suggest upgrade.

2. **Resolve the PR**
   Run `gh pr view --json number,url,headRefName`. If the user provided a PR number/URL, use that instead.

3. **List failing checks**
   Run `gh pr checks`. For each failing entry:
   - If `detailsUrl` is NOT a GitHub Actions URL → label as external, output the URL, and skip.
   - If GitHub Actions → extract the run ID from `detailsUrl`.

4. **Parse workflow YAML**
   Read `.github/workflows/*.yml` for the failing workflow.
   - Identify `jobs.*.needs` to find upstream dependencies.
   - Determine if the root cause is an upstream job — focus debugging there.

5. **Fetch logs**
   Run `gh run view <run_id> --log-failed` (or `--log` if `--log-failed` isn't available).
   If the log is very large (> 500 lines), use `scripts/inspect_pr_checks.py --repo . --pr <number>` if present, or pipe through `tail -n 200`.

6. **Detect failure pattern**
   From log output, identify:
   - **Flaky test** → re-run failed jobs; consider test retry logic
   - **Timeout** → increase `timeout-minutes` in workflow YAML
   - **OOM** → use larger runner or reduce parallelism
   - **Dependency/network** → add caching or retry step
   - **Code error** → fix in source

7. **Summarize and propose fix**
   Show: check name, run URL, root-cause job, pattern (if any), and a short log snippet.
   Draft the fix (code change, YAML change, or rerun suggestion).
   Ask: "Implement this fix? (yes/no)"

8. **Implement after approval**
   Apply changes. For YAML fixes, edit `.github/workflows/<file>.yml`.

9. **Rerun checks**
   Run `gh run rerun <run_id> --failed` (only failed jobs).
   If `--failed` isn't supported, fall back to `gh run rerun <run_id>` and note it reruns all jobs.

10. **Confirm**
    Run `gh pr checks` after rerun and confirm all checks pass.

## Error Handling

- Missing `workflow` scope → `gh auth login` with scope
- External CI → report URL only; do not debug
- Log too large → use `scripts/inspect_pr_checks.py` or `tail`
- `--failed` not supported → full rerun fallback
- `rerun: permission denied` → verify write access to Actions
- Timeout waiting for checks → suggest `gh pr checks --watch`
