#!/usr/bin/env bash
# sync.sh — pull dotfiles, run install, email results
#
# macOS / Linux : symlinks make ~/.claude live, no mirror step needed.
# Windows       : two-way copy mirror — ~/.claude → dotfiles before commit, dotfiles → ~/.claude after pull.
#
# set -uo (no -e): we want all steps to run even if one fails, and we capture exit codes ourselves.
set -uo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_SRC="$DOTFILES_DIR/claude"

if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
  HOME_DIR="$(cygpath -u "$USERPROFILE")"
  IS_WINDOWS=true
else
  HOME_DIR="$HOME"
  IS_WINDOWS=false
fi

CLAUDE_DEST="$HOME_DIR/.claude"
EMAIL="dsylvesteriii@gmail.com"
SUBJECT="Dotfiles Sync — $(date '+%Y-%m-%d %H:%M')"
LOG=$(mktemp)

# Keep in sync with install.sh ENTRIES array.
ENTRIES=(
  "CLAUDE.md"
  "mcp.json"
  "settings.json"
  "statusline-command.sh"
  "docs"
  "skills"
  "agents"
  "commands"
  ".vault"
)

mirror_entry() {
  # mirror_entry <src> <dest>
  local src="$1"
  local dest="$2"
  if [[ ! -e "$src" ]]; then return 0; fi
  if [[ -d "$src" ]]; then
    mkdir -p "$dest"
    cp -R "$src/." "$dest/"
  else
    cp -f "$src" "$dest"
  fi
}

mirror_to_dotfiles() {
  for entry in "${ENTRIES[@]}"; do
    mirror_entry "$CLAUDE_DEST/$entry" "$CLAUDE_SRC/$entry"
  done
}

mirror_to_claude() {
  for entry in "${ENTRIES[@]}"; do
    mirror_entry "$CLAUDE_SRC/$entry" "$CLAUDE_DEST/$entry"
  done
}

{
  echo "=== Dotfiles Sync: $(date) ==="
  if $IS_WINDOWS; then echo "Mode: copy (Windows)"; else echo "Mode: symlink (Unix)"; fi
  echo ""

  cd "$DOTFILES_DIR"

  # Safety: clear any leftover rebase state from a previous interrupted run,
  # so a sync never starts on top of a half-finished rebase (which would leave
  # conflict markers in tracked files).
  if [[ -d "$DOTFILES_DIR/.git/rebase-merge" || -d "$DOTFILES_DIR/.git/rebase-apply" ]]; then
    echo "WARNING: a previous rebase was left in progress — aborting it before sync."
    git rebase --abort 2>&1 || true
    echo ""
  fi

  # Windows: capture local ~/.claude edits into dotfiles BEFORE git ops.
  if $IS_WINDOWS; then
    echo "--- mirror ~/.claude → dotfiles/claude (capture local edits) ---"
    mirror_to_dotfiles
    echo ""
  fi

  echo "--- git add & commit local changes ---"
  git add -A 2>&1
  git diff --cached --quiet 2>&1
  if [[ $? -ne 0 ]]; then
    git commit -m "chore: auto-sync $(hostname) $(date '+%Y-%m-%d %H:%M')" 2>&1
  else
    echo "(no local changes to commit)"
  fi
  echo ""

  echo "--- git pull --rebase ---"
  git pull --rebase origin main 2>&1
  PULL_EXIT=$?
  echo ""

  if [[ $PULL_EXIT -ne 0 ]]; then
    # HARDENING: a failed pull --rebase leaves conflict markers in the working
    # tree. Mirroring that state back into ~/.claude is exactly what corrupts
    # live config (settings.json, CLAUDE.md). On any rebase failure, abort the
    # rebase to restore a clean tree and SKIP both push and the mirror-back.
    echo "!!! git pull --rebase FAILED — aborting rebase; ~/.claude will NOT be touched."
    if [[ -d "$DOTFILES_DIR/.git/rebase-merge" || -d "$DOTFILES_DIR/.git/rebase-apply" ]]; then
      git rebase --abort 2>&1 \
        && echo "Rebase aborted; repo restored to its pre-pull commit (your local commit is preserved)."
    fi
    PUSH_EXIT=1
    INSTALL_EXIT=0
  else
    echo "--- git push ---"
    git push origin main 2>&1
    PUSH_EXIT=$?
    echo ""

    # Windows: apply (rebased) state into ~/.claude AFTER git ops.
    # Unix: symlinks already make ~/.claude live; no mirror needed.
    if $IS_WINDOWS; then
      echo "--- mirror dotfiles/claude → ~/.claude (apply remote/rebased state) ---"
      mirror_to_claude
      INSTALL_EXIT=$?
      echo ""
    else
      echo "--- install.sh (refresh symlinks for any new tracked entries) ---"
      /bin/bash "$DOTFILES_DIR/install.sh" 2>&1
      INSTALL_EXIT=$?
      echo ""
    fi
  fi

  if [[ $PULL_EXIT -eq 0 && $PUSH_EXIT -eq 0 && $INSTALL_EXIT -eq 0 ]]; then
    echo "Status: SUCCESS"
  else
    echo "Status: FAILED (pull=$PULL_EXIT, push=$PUSH_EXIT, install=$INSTALL_EXIT)"
    if [[ $PULL_EXIT -ne 0 ]]; then
      echo "  -> Rebase conflict: resolve manually (cd \"$DOTFILES_DIR\"; git pull --rebase origin main; fix conflicts; git push), then re-run sync. ~/.claude was left untouched this run."
    fi
  fi

  echo "=== Done: $(date) ==="
} > "$LOG" 2>&1

# Send email via Gmail SMTP — password from macOS Keychain or env var
APP_PASSWORD=""
if command -v security >/dev/null 2>&1; then
  APP_PASSWORD=$(security find-generic-password -a "dsylvesteriii@gmail.com" -s "dotfiles-sync-smtp" -w 2>/dev/null || true)
fi
if [[ -z "$APP_PASSWORD" ]]; then
  APP_PASSWORD="${DOTFILES_SYNC_SMTP_PASSWORD:-}"
fi

# Find a python interpreter (python3 on macOS/Linux, python or py on Windows)
PYTHON=""
for candidate in python3 python py; do
  if command -v "$candidate" >/dev/null 2>&1; then
    PYTHON="$candidate"
    break
  fi
done

if [[ -n "$APP_PASSWORD" && -n "$PYTHON" ]]; then
  "$PYTHON" - "$EMAIL" "$SUBJECT" "$LOG" "$APP_PASSWORD" <<'PYEOF'
import sys, smtplib
from email.mime.text import MIMEText

to_addr, subject, log_path, password = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
with open(log_path) as f:
    body = f.read()

msg = MIMEText(body)
msg["Subject"] = subject
msg["From"] = to_addr
msg["To"] = to_addr

with smtplib.SMTP_SSL("smtp.gmail.com", 465) as s:
    s.login(to_addr, password)
    s.send_message(msg)

print("Email sent successfully")
PYEOF
else
  if [[ -z "$APP_PASSWORD" ]]; then
    echo "WARNING: SMTP password not found (set DOTFILES_SYNC_SMTP_PASSWORD or store in macOS Keychain as 'dotfiles-sync-smtp')"
  fi
  if [[ -z "$PYTHON" ]]; then
    echo "WARNING: no python interpreter on PATH (tried python3, python, py)"
  fi
fi

# Also keep a copy in the persistent log
cat "$LOG" >> "$DOTFILES_DIR/../.claude/dotfiles-sync.log"
rm -f "$LOG"

# Print log to stdout so the user sees the result when running interactively
cat "$DOTFILES_DIR/../.claude/dotfiles-sync.log" | tail -50
