---
name: monorepo-scaffold
description: Scaffold a production-ready Bun monorepo with /apis, /apps, /libs, and /infra workspaces. Creates folder structure, .gitkeep files for git tracking, workspace package.json files, .gitignore, .env.example, README, and a verifiable test command. Use when setting up a new monorepo project or adding workspace structure to an existing repo.
argument-hint: [project-name]
---

## Monorepo Scaffold Skill

When invoked, scaffold a full monorepo workspace structure following this pattern.

---

### Standard Layout

```
/
├── apis/                    # Backend APIs — one subfolder per API
│   └── <api-name>/          # e.g. auth0-mgmt, webhooks, internal
├── apps/                    # Frontend apps — one subfolder per app
│   ├── ops-ui/
│   └── client-portal/
├── libs/                    # Shared libraries consumed by all apis and apps
│   └── shared/              # Shared types, DTOs, utils, constants
├── infra/
│   ├── terraform/
│   └── cdk/
├── package.json             # Root Bun workspace config
├── .gitignore
├── .env.example
└── README.md
```

---

### Rules

1. **Always use `/apis` (plural)** — mirrors `/apps`, allows multiple APIs without restructuring
2. **Always use `/libs/shared`** — shared code lives here; never duplicate types/utils across workspaces
3. **Every workspace directory gets a `.gitkeep`** — git suppresses empty folders; `.gitkeep` preserves structure on fresh clone
4. **`.gitignore` must NOT suppress `.gitkeep`** — verify this explicitly
5. **Every workspace gets its own `package.json`** — required for Bun workspace resolution
6. **Root `package.json` must have a `"workspaces"` array** listing all workspace paths

---

### Files to Create

#### Root `package.json`
```json
{
  "name": "<project-name>",
  "version": "0.0.1",
  "private": true,
  "workspaces": [
    "apis/*",
    "apps/*",
    "libs/*"
  ],
  "scripts": {
    "lint": "bun run --filter='*' lint",
    "build": "bun run --filter='*' build",
    "test": "bun run --filter='*' test"
  }
}
```

#### Root `.gitignore`
Must include — and must NOT include `.gitkeep`:
```
node_modules/
dist/
.env
*.env.local
.turbo/
.cache/
*.tsbuildinfo
```

#### Root `.env.example`
Document every env var used across all workspaces. Group by workspace with comments:
```
# apis/auth0-mgmt
AUTH0_DOMAIN=
AUTH0_CLIENT_ID=
AUTH0_CLIENT_SECRET=
...
```

#### Per-workspace `package.json` (apis, apps, libs)
```json
{
  "name": "@<project>/<workspace-name>",
  "version": "0.0.1",
  "private": true,
  "scripts": {
    "lint": "eslint .",
    "build": "bun build ./src/index.mts --outdir dist",
    "test": "bun test"
  }
}
```

#### `.gitkeep` files
Create an empty `.gitkeep` in every workspace and infra directory:
```
apis/<api-name>/.gitkeep
apps/ops-ui/.gitkeep
apps/client-portal/.gitkeep
libs/shared/.gitkeep
infra/terraform/.gitkeep
infra/cdk/.gitkeep
```
Stage all `.gitkeep` files with `git add` immediately after creation.

#### `README.md`
Must cover:
1. Prerequisites (Bun version, Docker Desktop)
2. `bun install` — install all workspace deps from root
3. `docker compose up -d` — start local services
4. How to run each api/app in dev mode
5. How to reset local database

---

### Test Command to Include in Task

Every task using this scaffold must include this verifiable test block:

```bash
# 1. Verify folder structure
for dir in apis/<api-name> apps/ops-ui apps/client-portal libs/shared infra/terraform infra/cdk; do
  [ -d "$dir" ] && echo "✅ $dir" || { echo "❌ MISSING: $dir"; exit 1; }
done

# 2. Verify .gitkeep files exist
for gitkeep in apis/<api-name>/.gitkeep apps/ops-ui/.gitkeep apps/client-portal/.gitkeep libs/shared/.gitkeep infra/terraform/.gitkeep infra/cdk/.gitkeep; do
  [ -f "$gitkeep" ] && echo "✅ $gitkeep" || { echo "❌ MISSING: $gitkeep"; exit 1; }
done

# 3. Verify .gitkeep files are tracked by git
for gitkeep in apis/<api-name>/.gitkeep apps/ops-ui/.gitkeep apps/client-portal/.gitkeep libs/shared/.gitkeep infra/terraform/.gitkeep infra/cdk/.gitkeep; do
  git ls-files --error-unmatch "$gitkeep" > /dev/null 2>&1 && echo "✅ git-tracked: $gitkeep" || { echo "❌ NOT TRACKED IN GIT: $gitkeep"; exit 1; }
done

# 4. Verify required files
for file in package.json .gitignore .env.example README.md apis/<api-name>/package.json apps/ops-ui/package.json apps/client-portal/package.json libs/shared/package.json; do
  [ -f "$file" ] && echo "✅ $file" || { echo "❌ MISSING: $file"; exit 1; }
done

# 5. Verify workspaces key in root package.json
grep -q '"workspaces"' package.json && echo "✅ workspaces key present" || { echo "❌ workspaces key missing"; exit 1; }

# 6. Verify .gitignore does not suppress .gitkeep
grep -q '\.gitkeep' .gitignore && { echo "❌ .gitignore is suppressing .gitkeep files"; exit 1; } || echo "✅ .gitkeep not ignored"

# 7. Install, lint, build
bun install && bun run lint && bun run build
```

---

### Acceptance Criteria Pattern

When writing a task spec for a monorepo scaffold, use this AC structure:

**Folder Structure** — one `[ -d <path> ]` check per directory
**Git-Tracked Directories** — one `[ -f <path>/.gitkeep ]` + `git ls-files --error-unmatch` check per directory
**Required Files** — one `[ -f <path> ]` check per file including per-workspace package.json
**Workspace Integrity:**
- POSITIVE: `bun install` from root installs all workspace deps with zero errors
- POSITIVE: `bun run lint` from root lints all workspaces without errors
- POSITIVE: `bun run build` from root produces zero TypeScript errors
- NEGATIVE: A workspace listed in root package.json but missing its directory causes `bun install` to exit non-zero with a descriptive error
- NEGATIVE: A cross-workspace import without a barrel `index.mts` produces a TypeScript error at build time — not a runtime error
