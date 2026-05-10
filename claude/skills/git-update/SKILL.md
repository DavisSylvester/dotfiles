---
name: git-update
description: Stage and commit pending changes. If the current branch is `main` or `master`, first create a `feature/<short-summary>` branch (≤ 50 chars total). Generates a Conventional Commit message from the diff when one is not provided. Use when the user says "git update", "commit my changes", "stage and commit", or asks to commit while on main.
argument-hint: [optional commit subject]
---

# git-update

Stage all pending changes, create a feature branch if necessary, and produce a Conventional Commit. Adheres to git-flow and Conventional Commits per `~/.claude/CLAUDE.md`.

## Process

Run these steps in order. Use one Bash call per logical step so failures surface clearly.

### 1. Inspect repo state

```bash
git rev-parse --is-inside-work-tree   # bail if not a git repo
git branch --show-current              # capture current branch
git status --short                     # see what's pending
git diff --stat                        # quick scope of changes
git diff --cached --stat               # staged changes already
```

If `git status` shows **no pending changes** (nothing staged, nothing unstaged, no untracked), stop immediately and tell the user there is nothing to commit.

### 2. Branch decision

- If current branch is **not** `main` or `master`: stay on it. Skip to step 3.
- If current branch **is** `main` or `master`: create a feature branch **before** any `git add` / `git commit`.

#### Generating the feature branch name

- Read the diff (`git diff` + `git diff --cached`) and untracked-file list (`git status --short`). Derive a short, descriptive summary of what changed.
- Format: `feature/<kebab-case-summary>`
- **Hard cap: 50 characters total**, including the `feature/` prefix (so the summary has ≤ 42 chars).
- Lowercase. Letters, digits, and `-` only. No slashes inside the summary, no consecutive hyphens, no leading/trailing hyphen.
- Examples (good):
  - `feature/add-angular-scaffold-agent`
  - `feature/fix-windows-symlink-bug`
  - `feature/update-scss-tailwind-rule`
  - `feature/add-vault-folder`
- Examples (bad):
  - `feature/changes` (too vague)
  - `feature/Update_thing` (uppercase, underscore)
  - `feature/this-is-a-very-long-name-that-clearly-exceeds-fifty-chars` (over cap)

If the user passed a commit-subject argument, derive the branch name from that subject (strip type prefix, kebab-case, truncate). Otherwise derive from the diff.

Create the branch:

```bash
git checkout -b feature/<summary>
```

Verify it stuck:

```bash
git branch --show-current
```

### 3. Stage changes

Prefer **adding files by name** over `git add -A` so secrets and large binaries don't sneak in. Look at `git status --short` and stage each tracked + untracked path explicitly:

```bash
git add path/to/file1 path/to/file2 ...
```

Skip any file that looks like a secret (`.env`, `credentials.json`, `*.pem`, `*.key`). If you skip files, mention it in the response.

If the file list is large (> 20) and clearly clean, `git add -A` is acceptable — call it out explicitly.

### 4. Commit

Generate a Conventional Commit subject if the user didn't provide one. Pick the type from the actual changes:

- `feat:` new functionality
- `fix:` bug fix
- `refactor:` internal change without behavior change
- `chore:` build, deps, tooling, sync
- `test:` test-only changes
- `docs:` doc-only changes

Subject rules:
- Imperative mood ("add", not "added" / "adds")
- Lowercase after the colon, no trailing period
- ≤ 72 characters
- Body (optional) wraps at ~72 chars; one blank line between subject and body

Use a HEREDOC for multiline messages:

```bash
git commit -m "$(cat <<'EOF'
feat: add angular-scaffold-agent and update style rule

- agents/angular-scaffold-agent.md: new global agent
- CLAUDE.md: replace "SCSS only" with "ask SCSS or Tailwind"
EOF
)"
```

If a pre-commit hook fails: do **not** retry with `--no-verify`. Read the hook output, fix the underlying problem, re-stage, and create a **new** commit (never `--amend` after a hook failure — the previous commit is still the parent).

### 5. Confirm

Run `git status` and `git log -1 --oneline` to verify success. Report back:
- The branch you're on now (and whether it was newly created).
- The commit SHA + subject.
- Anything skipped (secrets, etc.).

## Do NOT do these things

- **Do not push.** Pushing is a separate, explicit action — only push when the user says so.
- **Do not run `git add -A` blindly.** Stage by name unless the file list is clean and you've called that out.
- **Do not commit on `main`/`master`.** Always branch off first.
- **Do not bypass hooks** with `--no-verify`, `--no-gpg-sign`, etc.
- **Do not amend** to fix a failed hook — make a new commit.
- **Do not commit secrets**: `.env`, `*.credentials.json`, `*.pem`, `*.key`, anything matching obvious credential patterns. If unsure, skip and ask.

## Argument handling

When the skill is invoked with an argument, treat the argument as the commit **subject** (the line after the type prefix). Pick the type yourself from the diff:

- Input: `add vault folder`
- Output: `feat: add vault folder` (after diff inspection — could be `chore:` if it's just a config change)

If the argument already includes a Conventional Commit type prefix (`feat: ...`, `fix: ...`), use it verbatim.
