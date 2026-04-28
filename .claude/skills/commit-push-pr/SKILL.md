---
name: commit-push-pr
description: Authoritative for commits, pushes, and PRs in the Cerebro repo. Wraps every git and gh call so the agent identity loaded from `.envrc` (`AGENT_GH_TOKEN`, `AGENT_GIT_{AUTHOR,COMMITTER}_*`) is opted into per-call — without it, commits get attributed to rbrtbn (the human) instead of rbrtbn-agent. Use whenever the user asks to commit, push, open a PR, mark a PR ready, or finish a branch in this working directory.
---

# commit-push-pr (Cerebro)

## Why this exists

`.envrc` exports the agent's GitHub identity under `AGENT_*` names so a regular shell in this directory keeps the human's `gh auth` and git config untouched. The agent identity is **opt-in**: only this skill (or a manual invocation of `scripts/as-agent`) maps the `AGENT_*` vars onto the names git and gh actually read (`GH_TOKEN`, `GIT_{AUTHOR,COMMITTER}_*`). Plain `git` / `gh` here will be attributed to the human.

The wrapper also runs `direnv exec .` internally, so callers don't need to think about whether direnv is loaded ambiently (it isn't, in Claude's Bash tool).

## Pre-flight: identity check (once per session, before the first push)

```bash
.claude/skills/commit-push-pr/scripts/check-identity.sh
```

Exits non-zero if gh isn't authenticated as `rbrtbn-agent`. **Stop and surface to the user** on failure — never push with the wrong identity.

## Workflow

Every git/gh command goes through `bin/as-agent`. Capture state in parallel first:

- `bin/as-agent git status`
- `bin/as-agent git diff HEAD`
- `bin/as-agent git branch --show-current`

### 1. Branch

If on `main`, create one — never commit to `main`:

- Issue-linked work → `<issue-number>-<kebab-slug>` (e.g. `7-eversports-worker`).
- Otherwise → short kebab-slug (e.g. `docs-readme-naming`).
- `bin/as-agent git checkout -b <branch>`

### 2. Commit

- Conventional Commits subject, imperative mood, ≤ 72 chars, no trailing period.
- Body explains *why*, not *what*.
- Stage by filename — never `git add -A` / `git add .`.
- Always include the `Co-Authored-By` trailer.

```bash
bin/as-agent git add <files>
bin/as-agent git commit -m "$(cat <<'EOF'
<type>: <subject>

<body>

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

### 3. Push

`bin/as-agent git push -u origin <branch>` (drop `-u` if upstream is already set).

### 4. Open the PR — draft vs ready

Decide by readiness, not by reflex:

| Situation | Open as |
| --- | --- |
| Work is complete: `vp check` green, `vp test` green, all acceptance criteria from the issue checked, description fully filled in | **non-draft** (omit `--draft`) — or, if you already created a draft this session, run `as-agent gh pr ready <pr>` |
| In-flight work — first commit on a branch with more to come, or any gate not yet green | **`--draft`** |

Title = commit subject (or issue title if linked). Read `.github/pull_request_template.md` and fill it in for the body — every section, "n/a" only when a section truly doesn't apply.

```bash
bin/as-agent gh pr create [--draft] --title "<title>" --body "$(cat <<'EOF'
<filled template>

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

Return the PR URL.

## Don'ts

- Never run plain `git` / `gh` in this repo. If you catch a missing `as-agent` prefix, rerun the command with it.
- Never push to `main`. Branch protection rejects it server-side anyway.
- Never `--no-verify` or `--no-gpg-sign` unless the user explicitly asks.
- Don't mark a draft ready until the gates above are green.
