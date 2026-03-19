# dotfiles

Personal Claude Code configuration — synced across Windows, Linux, and Mac via git.

## What's here

```
claude/
  CLAUDE.md                        # Global development standards
  docs/
    bun.md                         # Bun runtime & toolchain reference
    elysia.md                      # Elysia API framework reference
    azure.md                       # Azure development standards
  skills/
    monorepo-scaffold/SKILL.md     # Custom scaffold skill
  memory/                          # Claude memory files (synced)
```

**Not tracked** (machine-specific): `settings.json`, `.credentials.json`, cache, debug logs, session history, IDE locks.

---

## Setup on a new machine

### 1. Clone this repo

```bash
# Linux / Mac
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/dotfiles

# Windows (PowerShell)
git clone https://github.com/YOUR_USERNAME/dotfiles.git $env:USERPROFILE\dotfiles
```

### 2. Create symlinks

Claude Code will use your `~/.claude/` directory. Symlink the portable files into it so changes sync via git.

**Linux / Mac**
```bash
# Back up any existing files first
mv ~/.claude/CLAUDE.md ~/.claude/CLAUDE.md.bak 2>/dev/null
mv ~/.claude/docs ~/.claude/docs.bak 2>/dev/null
mv ~/.claude/skills ~/.claude/skills.bak 2>/dev/null
mv ~/.claude/memory ~/.claude/memory.bak 2>/dev/null

# Create symlinks
ln -sf ~/dotfiles/claude/CLAUDE.md ~/.claude/CLAUDE.md
ln -sf ~/dotfiles/claude/docs ~/.claude/docs
ln -sf ~/dotfiles/claude/skills ~/.claude/skills
ln -sf ~/dotfiles/claude/memory ~/.claude/memory
```

**Windows (PowerShell — run as Administrator, or enable Developer Mode)**
```powershell
# Back up any existing files first
Rename-Item "$env:USERPROFILE\.claude\CLAUDE.md" "CLAUDE.md.bak" -ErrorAction SilentlyContinue
Rename-Item "$env:USERPROFILE\.claude\docs" "docs.bak" -ErrorAction SilentlyContinue
Rename-Item "$env:USERPROFILE\.claude\skills" "skills.bak" -ErrorAction SilentlyContinue
Rename-Item "$env:USERPROFILE\.claude\memory" "memory.bak" -ErrorAction SilentlyContinue

# Create symlinks
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.claude\CLAUDE.md"  -Target "$env:USERPROFILE\dotfiles\claude\CLAUDE.md"
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.claude\docs"        -Target "$env:USERPROFILE\dotfiles\claude\docs"
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.claude\skills"      -Target "$env:USERPROFILE\dotfiles\claude\skills"
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.claude\memory"      -Target "$env:USERPROFILE\dotfiles\claude\memory"
```

> **Windows note:** Symlinks require either Developer Mode (Settings → System → For developers → Developer Mode) or running PowerShell as Administrator.

---

## Day-to-day sync

```bash
# Pull changes from another machine
cd ~/dotfiles && git pull

# Push changes made on this machine
cd ~/dotfiles && git add -A && git commit -m "chore: update claude config" && git push
```

---

## settings.json

`settings.json` is **not synced** — it contains machine-specific paths, project-specific Bash allow rules, and Windows/Linux path differences. Configure it manually on each machine. Use Claude Code's settings UI or edit `~/.claude/settings.json` directly.
