---
name: gh-open-pr
description: Stage, commit, push, and open a GitHub pull request in one flow using the GitHub CLI (gh). Use only when the user explicitly asks to create a PR, push and open PR, commit and push, or "yeet" their changes.
---

# gh Open PR

Stage, commit, push the current branch, and open a GitHub pull request in one flow.

## When to Use

- User says "create a PR", "open a PR", "push and open PR", or "yeet"
- User has uncommitted changes ready to ship
- User wants to commit their work and put it up for review

## Prerequisites

- `gh` installed and authenticated (`gh auth status`).
- Must be inside a git repo (`git status` succeeds).
- Run `git status` first to confirm there are changes to commit.

## Instructions

### Step 1 — Determine branch

```bash
CURRENT=$(git branch --show-current)
DEFAULT=$(gh repo view --json defaultBranchName --jq .defaultBranchName)

# If on the default branch, create a new one
if [ "$CURRENT" = "$DEFAULT" ]; then
  # Detect branch prefix from conventions rule or config/settings.json
  # Default: codex/<description>
  git checkout -b codex/<short-description>
fi
```

### Step 2 — Stage and commit

```bash
git status -sb                   # review what will be staged
git add -A
git commit -m "<terse present-tense description>"
```

Follow the `github-branch-commit-conventions` rule:
- If repo uses Conventional Commits → `feat(scope): description`
- If PR template exists → PR body must use it
- Default → one short line

### Step 3 — (Optional) run project checks

If `config/settings.json` has `"checkStatusBeforePush": true`, run the project's lint/test command before pushing (e.g. `dart test`, `npm test`, `flutter test`). Only proceed if checks pass.

### Step 4 — Push

```bash
git push -u origin $(git branch --show-current)
```

If push fails due to upstream divergence:
```bash
git pull --rebase origin <base-branch>
git push -u origin $(git branch --show-current)
```

### Step 5 — Create the PR

Write the PR body to a temp file to preserve formatting:

```bash
cat > /tmp/pr-body.md << 'EOF'
## Summary
<One-paragraph summary of what this PR does>

## Problem
<What problem does this solve?>

## Solution
<How does the implementation solve it?>

## Validation
<How was this tested / verified?>
EOF

gh pr create \
  --title "[codex] <short-description>" \
  --body-file /tmp/pr-body.md \
  --draft
```

If `config/settings.json` has `"preferDraftPRs": false`, omit `--draft`.

### Step 6 — Confirm

```bash
gh pr view --json number,url,title | jq '{number,url,title}'
```

Output the PR URL so the user can open it.

## Validation

- `gh pr view` returns the new PR with expected title and branch.
- PR URL opens in browser and shows the correct diff.
- If checks are configured, `gh pr checks` shows them running or passing.

## Error Handling

| Error | Next step |
|-------|-----------|
| `gh: not authenticated` | Run `gh auth login` |
| `push rejected (non-fast-forward)` | Run `git pull --rebase` then retry push |
| `already a pull request for this branch` | Run `gh pr view` to find existing PR |
| `gh: outdated version` | Run `brew upgrade gh` or follow OS instructions |
