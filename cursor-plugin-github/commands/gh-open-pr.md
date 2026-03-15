---
name: gh-open-pr
description: Stage, commit, push, and open a draft pull request for the current work in one flow.
---

# Open a GitHub PR

## Applies to
files: ["*"]

## Command

Stage all changes, commit, push, and create a GitHub pull request for the current branch.

Steps:

1. **Verify `gh` auth**
   Run `gh auth status`. If not authenticated, stop and ask the user to run `gh auth login` first.
   If `gh` is missing, ask the user to install it: `brew install gh` (macOS) or visit https://cli.github.com.

2. **Check for uncommitted changes**
   Run `git status -sb`. If there is nothing to commit, ask the user what they want to include.

3. **Handle branch**
   Run `git branch --show-current` and `gh repo view --json defaultBranchName`.
   - If on the default branch, create a new branch first — ask the user for a short description, then: `git checkout -b codex/<description>`
   - Otherwise, stay on the current branch.

4. **Stage and commit**
   Run `git add -A` then `git commit -m "<terse summary>"`.
   Apply conventions from the `github-branch-commit-conventions` rule (detect PR template, commitlint, or recent branch patterns before choosing the format).

5. **Run project checks (optional)**
   If `config/settings.json` has `"checkStatusBeforePush": true`, run the repo's test/lint command. If checks fail, show output and ask the user whether to fix first or push anyway.

6. **Push**
   Run `git push -u origin $(git branch --show-current)`.
   - If push fails with a non-fast-forward error, run `git pull --rebase` and retry.
   - If push fails with a workflow/auth error, ask the user to re-authenticate and retry.

7. **Create the PR**
   Write PR body to `/tmp/gh-pr-body.md` with sections: Summary, Problem, Solution, Validation.
   Run:
   ```
   gh pr create --title "[codex] <summary>" --body-file /tmp/gh-pr-body.md --draft
   ```
   If `config/settings.json` has `"preferDraftPRs": false`, omit `--draft`.

8. **Confirm**
   Run `gh pr view --json number,url,title` and output the PR URL to the user.

**Ask before step 7**: "Ready to create the PR with title `[codex] <summary>`? (yes/no)"

## Error Handling

- `gh: not authenticated` → prompt `gh auth login`, retry
- `push rejected` → run `git pull --rebase`, retry push
- `PR already exists for this branch` → run `gh pr view` and show the existing PR URL
- Outdated `gh` → show `gh --version`, suggest `brew upgrade gh` or OS equivalent
- Long-running push times out → suggest retrying; check network and repo size
