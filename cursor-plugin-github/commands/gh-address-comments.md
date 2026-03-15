---
name: gh-address-comments
description: Fetch review and issue comments on the open PR for the current branch, group by file/line, and address selected comments.
---

# Address PR Comments

## Applies to
files: ["*"]

## Command

Fetch all review comments on the current PR and help the user address them.

Steps:

1. **Verify `gh` auth**
   Run `gh auth status`. If not authenticated, stop and ask the user to run `gh auth login`.

2. **Find the current PR**
   Run `gh pr view --json number,url,title`. If no PR exists for this branch, output the URL to create one and stop.

3. **Fetch comments** (prefer MCP; fall back to `gh api`)
   - Inline review comments: `gh api repos/{owner}/{repo}/pulls/{pr}/comments`
   - PR-level review bodies: `gh pr view {pr} --json reviews`
   - Issue-level comments: `gh api repos/{owner}/{repo}/issues/{pr}/comments`

4. **Group and display**
   Group inline comments by `path:line`. Show numbered list:
   ```
   1. [file.dart:42] @reviewer — "comment text" → suggested fix
   2. [General] @reviewer — "comment text" → suggested fix
   ```

5. **Ask user which to address**
   "Which comments would you like to address? (e.g. 1,2 or 'all')"

6. **Apply fixes**
   For each selected comment, make the code/docs change. Optionally post a reply via:
   `gh api repos/{owner}/{repo}/pulls/{pr}/comments/{id}/replies --method POST --field body="Fixed: <explanation>"`

7. **Commit and push**
   After all fixes: `git add -A && git commit -m "Address PR review comments" && git push`

8. **Confirm**
   Run `gh pr view --web` to let the user verify threads are resolved in the GitHub UI.

## Error Handling

- `gh: not authenticated` → prompt `gh auth login`
- `404 on gh api` → verify PR number; re-run `gh pr view`
- MCP unavailable → fall back to `gh api` (step 3 option B)
- No comments to address → output "No open review comments found on this PR"
- Long log output → pipe through `head -n 100` and suggest full review in browser
