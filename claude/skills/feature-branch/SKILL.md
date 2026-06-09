---
name: feature-branch
description: Create a new gitflow-style `feature/<short-summary>` branch off an up-to-date `main`/`master`. Refuses if the working tree is dirty. Use when the user says "create a feature branch", "new feature branch", "start a feature", "gitflow feature start", or "branch off main".
argument-hint: <short feature summary>
---

# feature-branch

Create a gitflow-style feature branch off the latest `main`/`master`. Adheres to git-flow naming and the conventions in `~/.claude/CLAUDE.md`.

This skill **does not** stash, commit, or push — it only fast-forwards the base branch and cuts a new branch from it.

## Process

Run these steps in order. Use one Bash call per logical step so failures surface clearly.

### 1. Verify environment and inputs

```bash
git rev-parse --is-inside-work-tree   # bail if not a git repo
git branch --show-current              # capture current branch
git status --short                     # see what's pending
```

If no argument was passed, stop and ask the user for a short feature summary (a few words describing the feature). Do not invent one.

### 2. Refuse on a dirty tree

If `git status --short` shows **any** staged, unstaged, or untracked changes, stop immediately. Report the dirty paths and tell the user to either commit them (via `/git-update`), stash them (`git stash push -u -m "<reason>"`), or discard them — then re-run this skill. Do **not** auto-stash.

Exception: if every dirty path is clearly unrelated (e.g. `.ai/conversations/*.md` from `/docs`), surface the list and ask the user whether to proceed anyway. Default is still to refuse.

### 3. Pick the base branch

Detect which long-lived branch this repo uses:

```bash
git show-ref --verify --quiet refs/heads/main && echo main || echo master
```

Call that `<base>`. If neither exists locally, fall back to `git symbolic-ref refs/remotes/origin/HEAD` and strip `refs/remotes/origin/` from the result.

### 4. Update the base branch

```bash
git checkout <base>
git pull --ff-only
```

If the pull is not a fast-forward, stop and report. Do not merge or rebase silently — the user needs to resolve divergence before branching.

### 5. Derive the branch name

Take the argument and normalize it:

- Format: `feature/<kebab-case-summary>`
- **Hard cap: 50 characters total**, including the `feature/` prefix (summary ≤ 42 chars).
- Lowercase only. Letters, digits, and `-`. Collapse spaces/underscores to single `-`. Strip leading/trailing `-`. No consecutive `-`.
- Strip any leading `feature/` the user already included.
- If the user passed a Conventional Commit subject like `feat: add vault folder`, drop the type prefix (`feat:`) before kebab-casing.
- If after normalization the summary is empty or just punctuation, stop and ask for a clearer summary.
- Examples (good):
  - input `add angular scaffold agent` → `feature/add-angular-scaffold-agent`
  - input `fix Windows symlink bug` → `feature/fix-windows-symlink-bug`
  - input `feat: update scss tailwind rule` → `feature/update-scss-tailwind-rule`
- Examples (bad):
  - `feature/changes` (too vague — ask for more detail)
  - `feature/Update_thing` (uppercase, underscore)
  - `feature/this-is-a-very-long-name-that-clearly-exceeds-fifty-chars` (over cap — truncate at a word boundary)

### 6. Reject collisions

Before creating, check the name is not already in use locally or on origin:

```bash
git show-ref --verify --quiet refs/heads/feature/<summary>          # local
git ls-remote --exit-code --heads origin feature/<summary>          # remote
```

If either exists, stop and ask the user for a different name (or whether to check out the existing branch instead — don't decide for them).

### 7. Create and verify

```bash
git checkout -b feature/<summary>
git branch --show-current
```

### 8. Report

Tell the user:

- The new branch name (and that it was created from `<base>@<sha>`).
- The base branch's SHA after the pull (so they know what they branched from).
- That nothing has been pushed yet (they can run `git push -u origin feature/<summary>` when ready).

## Do NOT do these things

- **Do not stash, commit, or push** — this skill only branches. Side effects belong to the user.
- **Do not force-update `main`/`master`** (`git reset --hard`, `git fetch --prune` with deletions). Only `git pull --ff-only`.
- **Do not branch from a dirty tree.** Surface the dirt and let the user decide.
- **Do not silently truncate or rewrite a user-supplied name** past the 50-char cap or kebab-case normalization — show the normalized name back to the user in the report.
- **Do not create the branch if the name collides** with a local or remote branch.

## Argument handling

The argument is the feature **summary**, not a commit message. Examples:

- Input: `add vault folder` → branch `feature/add-vault-folder`
- Input: `fix windows symlink bug` → branch `feature/fix-windows-symlink-bug`
- Input: `feat: drop frozen lockfile in deploy` → branch `feature/drop-frozen-lockfile-in-deploy`

If no argument is provided, stop and ask for one — do not infer from the diff (this skill runs on a clean tree, so there is no diff to read from).
