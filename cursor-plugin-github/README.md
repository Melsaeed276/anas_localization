# Cursor GitHub Plugin

A Cursor plugin that enables the AI agent to manage GitHub pull requests, issues, CI checks, and releases using the GitHub CLI (`gh`) and optional GitHub MCP — with consistent repo-aware conventions.

---

## Prerequisites

| Dependency | Required | Notes |
|------------|----------|-------|
| [GitHub CLI (`gh`)](https://cli.github.com) | Yes | Install: `brew install gh` (macOS) or visit https://cli.github.com |
| `gh` authentication | Yes | Run `gh auth login` once; ensure `repo` and `workflow` scopes |
| Python 3 | Optional | Required only if using `scripts/inspect_pr_checks.py` |
| GitHub MCP server | Optional | Improves reliability for reading PR comments and issues; configure in `.mcp.json` |

---

## Installation

1. Open Cursor settings → **Plugins** → **Browse Marketplace**.
2. Search for `github` and click **Install**.

Or install from a local folder during development:
1. Clone/copy this directory.
2. In Cursor settings → Plugins → **Install from folder**, point to `cursor-plugin-github/`.

---

## What's Included

### Rules (always active)

| File | Purpose |
|------|---------|
| `rules/gh-auth-first.mdc` | Always verify `gh auth status` before running any `gh` command |
| `rules/prefer-gh-for-github.mdc` | Use `gh` subcommands instead of raw `curl` or git-parsing |
| `rules/github-branch-commit-conventions.mdc` | Detect repo conventions; fall back to plugin defaults |
| `rules/git-safety.mdc` | Never force-push to main; confirm before destructive git ops |

### Skills

| Skill | Phase | Purpose |
|-------|-------|---------|
| `gh-pr-workflow` | 1 | View, inspect, and list PRs |
| `gh-open-pr` | 1 | Stage → commit → push → create PR in one flow |
| `gh-issues` | 1 | Create, list, view, and manage issues |
| `gh-address-pr-comments` | 2 | Fetch, group, and address PR review comments |
| `gh-fix-pr-checks` | 2 | Debug failing CI, detect patterns, fix and rerun |
| `gh-actions-basics` | 2 | Inspect Actions runs, re-run failed jobs |
| `gh-draft-management` | 3 | Convert draft ↔ ready, auto-assign reviewers from CODEOWNERS |
| `gh-repo-context` | 3 | Read CONTRIBUTING.md, CODEOWNERS, PR templates for conventions |

### Commands (run from the Cursor command palette)

| Command | Phase | Purpose |
|---------|-------|---------|
| `gh-open-pr` | 1 | Open a PR for current branch |
| `gh-create-issue` | 1 | Create a new GitHub issue |
| `gh-pr-status` | 1 | Show PR title, URL, checks, and diff summary |
| `gh-address-comments` | 2 | Address review/issue comments on the current PR |
| `gh-fix-ci` | 2 | Debug and fix failing GitHub Actions checks |
| `gh-rerun-failed-jobs` | 2 | Re-run only failed jobs in an Actions run |
| `gh-create-release` | 3 | Tag, changelog, and create a GitHub release |

---

## Usage

### Via command palette

Open Cursor command palette (`Cmd+Shift+P`) → type a command name (e.g. `gh-open-pr`) → the agent runs the workflow.

### Via chat

Ask the agent naturally:
- "Create a PR for my changes"
- "Show me the status of my PR"
- "Fix the failing CI checks"
- "Address the review comments on my PR"
- "Create an issue for the login bug"

The agent uses the plugin's rules and skills automatically.

---

## Configuration (Phase 3)

Create `config/settings.json` in the plugin root to customize defaults:

```json
{
  "defaultBranchPrefix": "codex/",
  "autoAssignReviewers": false,
  "preferDraftPRs": true,
  "checkStatusBeforePush": true
}
```

| Setting | Default | Effect |
|---------|---------|--------|
| `defaultBranchPrefix` | `codex/` | Branch prefix when no repo convention is detected |
| `autoAssignReviewers` | `false` | Auto-assign reviewers from CODEOWNERS when marking PR ready |
| `preferDraftPRs` | `true` | Create PRs as draft by default |
| `checkStatusBeforePush` | `true` | Run project tests/lint before `git push` |

Repo-level conventions (PR templates, commitlint, branch patterns) always override these settings.

---

## GitHub MCP (Optional, Phase 3)

Add `.mcp.json` to the plugin root to connect GitHub's MCP server. When configured:
- Skills use MCP tools for reading PR comments and listing issues (more reliable than parsing `gh` text output).
- Falls back to `gh api` and `gh` subcommands when MCP is unavailable.

See `.mcp.json` for the server configuration template.

---

## Error Handling

All commands apply these error-handling rules:
- **Auth failures**: stop and prompt `gh auth login` before retrying.
- **Outdated `gh`**: show current version, suggest `brew upgrade gh` or OS equivalent.
- **Long-running operations**: suggest timeouts or chunked reads (e.g. `gh run view --log` for large logs).
- **Push failures**: suggest `git pull --rebase` before retry; explain the rollback.
- **Missing permissions**: explain the required GitHub permission and how to verify it.

---

## Support

- GitHub CLI docs: https://cli.github.com/manual
- GitHub REST API: https://docs.github.com/en/rest
- Cursor Plugins reference: https://cursor.com/docs/reference/plugins
