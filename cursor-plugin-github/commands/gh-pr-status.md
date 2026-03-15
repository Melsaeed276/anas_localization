---
name: gh-pr-status
description: Show the status of the PR for the current branch — title, URL, check results, and a one-line diff summary.
---

# PR Status

## Applies to
files: ["*"]

## Command

Display a summary of the current branch's pull request status.

Steps:

1. **Verify `gh` auth**
   Run `gh auth status`. If not authenticated, stop and ask the user to run `gh auth login` first.

2. **Find the PR**
   ```
   gh pr view --json number,url,title,state,baseRefName,headRefName,isDraft
   ```
   - If no PR exists for the current branch, output: "No open PR for branch `<branch>`. Run the `gh-open-pr` command to create one."
   - If a PR is found, continue.

3. **List CI checks**
   ```
   gh pr checks
   ```
   For each check, note: name, status (pass ✓ / fail ✗ / pending ⏳), and duration.

4. **Diff summary**
   ```
   gh pr diff --stat
   ```
   This shows a one-line-per-file summary of additions and deletions.

5. **Print summary to user**
   Format output as:

   ```
   PR #<number>: <title>
   URL: <url>
   State: <open|draft|merged|closed>
   Base: <base-branch> ← <head-branch>

   Checks:
     ✓ build (45s)
     ✗ test (2m 10s) — FAILED
     ⏳ lint — pending

   Diff: +42 -7 across 5 files
   ```

   Highlight failing checks and suggest running the `gh-fix-ci` command if any checks failed.

## Error Handling

- `gh: not authenticated` → prompt `gh auth login`
- `no pull request found` → tell user to create one with `gh-open-pr`
- `gh pr checks` takes too long → suggest `gh pr checks --watch` with a timeout note
- Outdated `gh` → show `gh --version`, suggest upgrade
