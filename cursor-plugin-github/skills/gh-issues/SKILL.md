---
name: gh-issues
description: Create, list, view, and manage GitHub issues using the GitHub CLI. Use when the user asks to create an issue, list issues, view issue details, assign an issue, or add labels. When GitHub MCP is configured, prefer MCP tools for listing and viewing.
---

# gh Issues

Manage GitHub issues with the `gh` CLI (or MCP when configured).

## When to Use

- User says "create an issue", "file a bug", "open a ticket"
- User wants to list open or closed issues
- User wants to view or navigate to a specific issue
- User wants to assign or label an issue

## Prerequisites

- `gh` installed and authenticated (`gh auth status`).
- For MCP: GitHub MCP server configured in `.mcp.json`.

## Instructions

### Create an issue

```bash
# Interactive (prompts for title and body)
gh issue create

# Non-interactive
gh issue create \
  --title "Bug: login fails on Safari" \
  --body "Steps to reproduce: ..." \
  --label "bug" \
  --assignee "@me"
```

For multi-line bodies, write to a temp file:

```bash
cat > /tmp/issue-body.md << 'EOF'
## Description
<What is the problem?>

## Steps to Reproduce
1. ...

## Expected Behavior
...

## Actual Behavior
...

## Environment
...
EOF

gh issue create --title "Bug: ..." --body-file /tmp/issue-body.md
```

### List issues

```bash
gh issue list                          # open issues
gh issue list --state closed           # closed issues
gh issue list --state all              # all issues
gh issue list --label "bug"            # filter by label
gh issue list --assignee "@me"         # my assigned issues
gh issue list --limit 20               # limit results
gh issue list --json number,title,state,url   # structured output
```

### View an issue

```bash
gh issue view 42                       # summary in terminal
gh issue view 42 --web                 # open in browser
gh issue view 42 --json number,title,body,comments
```

### Edit an issue (labels, assignees, title)

```bash
gh issue edit 42 --add-label "priority: high"
gh issue edit 42 --add-assignee "username"
gh issue edit 42 --title "Updated title"
```

### Close / reopen an issue

```bash
gh issue close 42
gh issue close 42 --comment "Resolved in PR #55"
gh issue reopen 42
```

### Link an issue to a PR

In the PR body, include:
```
Closes #42
```
GitHub will auto-close the issue when the PR is merged.

## MCP Alternative

When GitHub MCP is configured, prefer MCP tools for read operations:
- Use MCP `list_issues` or `get_issue` for listing/viewing.
- Fall back to `gh issue list` / `gh issue view` when MCP is not available.

## Validation

- After `gh issue create`: output includes `https://github.com/<owner>/<repo>/issues/<number>`.
- After `gh issue list`: table shows issue numbers, titles, and state.
- After `gh issue view 42`: shows title, body, labels, and assignees.

## Error Handling

| Error | Next step |
|-------|-----------|
| `gh: not authenticated` | Run `gh auth login` |
| `issue not found` | Verify issue number and repo; run `gh repo view` |
| `cannot create issue (missing perms)` | Check repo write access with `gh api repos/{owner}/{repo}` |
