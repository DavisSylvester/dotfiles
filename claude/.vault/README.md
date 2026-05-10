# `.vault`

Cross-machine, git-synced store for **agent memory** — markdown notes that persist
across sessions and workstations via the dotfiles repo.

## How it syncs

`.vault` is listed in `ENTRIES` in `~/dotfiles/install.sh` and `~/dotfiles/sync.sh`.
Running `bash ~/dotfiles/sync.sh` mirrors `~/.claude/.vault/ ↔ ~/dotfiles/claude/.vault/`
and pushes to GitHub. On macOS the path is symlinked; on Windows it's a recursive copy.

## Layout (planned)

```
.vault/
  MEMORY.md           # index — one line per entry, points to the file below
  user/               # user profile / preferences memories
  feedback/           # corrections, approved patterns, "do this / don't do that"
  project/            # ongoing initiatives, deadlines, stakeholders
  reference/          # external system pointers (Linear projects, Slack channels, 
  knowledge-base/     # Knowledges bases 
  dashboards)
```

Each memory is a single `.md` file with this frontmatter:

```markdown
---
name: short title
description: one-line hook used to decide relevance in future sessions
type: user | feedback | project | reference
---

Body — for `feedback` / `project`, structure as a rule/fact + **Why:** + **How to apply:**
```

## Why this lives at `.claude/.vault/` instead of project-scoped memory

Memories under `.claude/projects/<encoded-path>/memory/` are tied to one working
directory. `.vault` is **global** — meant for facts that apply across every project
on every workstation (user identity, durable preferences, cross-project conventions).
