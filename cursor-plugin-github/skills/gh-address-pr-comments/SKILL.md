---
name: gh-address-pr-comments
description: Fetch, group by file/line, and address review or issue comments on the open GitHub PR for the current branch. Verify gh auth first. When GitHub MCP is available, use MCP tools for reading comments. Use when the user wants to respond to or fix PR review feedback.
---

# gh Address PR Comments

Fetch all review and issue comments on the current PR, group them by file/line for context, and address the ones the user selects.

## When to Use

- User says "address review comments", "fix the PR feedback", "respond to comments"
- User wants to see what reviewers said and act on it
- User wants to mark review threads as resolved

## Prerequisites

- `gh` installed and authenticated (`gh auth status`).
- Must be inside the repo that has the open PR.
- (Optional) GitHub MCP configured in `.mcp.json` for richer comment access.

## Instructions

### Step 1 — Find the PR

```bash
gh pr view --json number,url,baseRefName,headRefName
```

Extract `number` for subsequent API calls. If no PR found, ask user to create one first.

### Step 2 — Fetch comments

Use the most available method:

**Option A — GitHub MCP (preferred when configured)**
Use MCP tools to read review comments and issue comments — returns structured data without parsing.

**Option B — `gh api` (fallback)**

Fetch review (inline) comments:
```bash
OWNER=$(gh repo view --json owner --jq .owner.login)
REPO=$(gh repo view --json name --jq .name)
PR_NUMBER=<number from step 1>

# Inline review comments (attached to diff lines)
gh api repos/$OWNER/$REPO/pulls/$PR_NUMBER/comments \
  --jq '[.[] | {id, path, line, body, user: .user.login, resolved: false}]'

# PR-level review bodies
gh pr view $PR_NUMBER --json reviews \
  --jq '[.reviews[] | {id, state, author: .author.login, body}]'

# Issue-level (non-review) comments
gh api repos/$OWNER/$REPO/issues/$PR_NUMBER/comments \
  --jq '[.[] | {id, body, user: .user.login}]'
```

### Step 3 — Group by file/line

Organize inline comments by `path` (file) and `line` for context:

```
src/auth/login.dart:42
  → @reviewer: "This null check will throw if user is null here"

src/models/user.dart:15
  → @reviewer: "Consider making this field final"
```

For PR-level and issue-level comments, list them separately under a "General comments" section.

### Step 4 — Present numbered list

Show the user all comment threads, numbered:

```
1. [src/auth/login.dart:42] @reviewer — "This null check will throw…"
   → Suggested fix: add null guard
2. [src/models/user.dart:15] @reviewer — "Consider making this field final"
   → Suggested fix: add `final` keyword
3. [General] @reviewer — "Please add tests for the error case"
   → Suggested fix: add unit test
```

Ask: "Which comments would you like to address? (e.g. 1,3 or 'all')"

### Step 5 — Apply fixes

For each selected comment:
1. Navigate to the file and line indicated.
2. Apply the code or docs fix.
3. After fixing, optionally reply to the thread:
   ```bash
   gh api repos/$OWNER/$REPO/pulls/$PR_NUMBER/comments/$COMMENT_ID/replies \
     --method POST \
     --field body="Fixed in this commit — <brief explanation>"
   ```

### Step 6 — Mark threads as resolved (if supported)

GitHub's REST API supports resolving review threads via GraphQL. Use `gh api graphql`:

```bash
gh api graphql -f query='
mutation {
  resolveReviewThread(input: {threadId: "<thread-node-id>"}) {
    thread { isResolved }
  }
}'
```

The thread node ID is available from the reviews JSON. Only available for review threads, not issue comments.

### Step 7 — Commit and push

After addressing comments:
```bash
git add -A
git commit -m "Address PR review comments"
git push
```

## Validation

- Run `gh pr view --json reviews --jq '[.reviews[] | {state, author: .author.login}]'` — confirm any CHANGES_REQUESTED reviews have been updated.
- Open the PR in browser (`gh pr view --web`) and confirm comment threads show as resolved.
- Reviewer count and states visible in PR sidebar.

## Error Handling

| Error | Next step |
|-------|-----------|
| `gh: not authenticated` | Run `gh auth login` |
| `gh api: 404` | Confirm PR number and repo with `gh pr view` |
| GraphQL resolve fails | Manually resolve in GitHub UI; note thread node IDs may differ |
| MCP unavailable | Fall back to `gh api` (Option B) |
