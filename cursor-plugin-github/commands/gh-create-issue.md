---
name: gh-create-issue
description: Create a new GitHub issue with a title, description, optional labels, and optional assignee.
---

# Create a GitHub Issue

## Applies to
files: ["*"]

## Command

Create a new GitHub issue for the current repository.

Steps:

1. **Verify `gh` auth**
   Run `gh auth status`. If not authenticated, stop and ask the user to run `gh auth login` first.
   Check `gh --version`; if missing, ask the user to install: `brew install gh` or visit https://cli.github.com.

2. **Gather issue details**
   Ask the user (or derive from conversation context):
   - **Title**: one short sentence describing the problem or request.
   - **Body**: description of the issue (steps to reproduce, expected vs actual behavior, environment).
   - **Labels** (optional): e.g. `bug`, `enhancement`, `documentation`.
   - **Assignee** (optional): GitHub username, or `@me` to self-assign.

3. **Write the issue body to a temp file**
   Use this structure if the user hasn't provided a body:
   ```
   ## Description
   <what is the issue?>

   ## Steps to Reproduce (if bug)
   1. ...

   ## Expected Behavior
   ...

   ## Actual Behavior
   ...

   ## Environment
   OS/version/etc.
   ```
   Save to `/tmp/gh-issue-body.md`.

4. **Create the issue**
   ```
   gh issue create \
     --title "<title>" \
     --body-file /tmp/gh-issue-body.md \
     [--label "<label>"] \
     [--assignee "<username-or-@me>"]
   ```

5. **Confirm**
   Output the issue URL to the user, e.g.:
   `Issue created: https://github.com/<owner>/<repo>/issues/<number>`

**Ask before step 4**: "Create issue titled `<title>`? (yes/no)"

## Error Handling

- `gh: not authenticated` → prompt `gh auth login`, retry
- `missing required permissions` → verify the user has write access to the repo
- `label not found` → list available labels with `gh label list`, suggest closest match
- `repo not found` → confirm with `gh repo view` that the current directory is inside a valid git repo
- Outdated `gh` → show `gh --version`, suggest upgrade
