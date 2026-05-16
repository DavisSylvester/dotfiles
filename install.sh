#!/usr/bin/env bash
# install.sh — one-time setup for ~/.claude config
# macOS / Linux : creates symlinks into the dotfiles repo (live, zero-drift)
# Windows       : copies into ~/.claude (no symlinks; pair with sync.sh for two-way mirror)
#
# Idempotent. Safe to re-run.
set -euo pipefail

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

# Tracked entries — top-level paths under claude/ that get linked or copied.
# Keep in sync with sync.sh ENTRIES array.
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

echo "Dotfiles dir : $DOTFILES_DIR"
echo "Claude source: $CLAUDE_SRC"
echo "Claude dest  : $CLAUDE_DEST"
if $IS_WINDOWS; then echo "Mode         : copy (Windows)"; else echo "Mode         : symlink (Unix)"; fi
echo ""

mkdir -p "$CLAUDE_DEST"

# ---- Unix: symlink ----
link() {
  local src="$1"
  local dest="$2"

  if [[ ! -e "$src" ]]; then
    echo "  [skip]   $dest  (not present in dotfiles)"
    return
  fi

  if [[ -L "$dest" ]]; then
    echo "  [skip]   $dest  (already a symlink)"
    return
  fi

  if [[ -e "$dest" ]]; then
    local backup="${dest}.bak"
    echo "  [backup] $dest → $backup"
    mv "$dest" "$backup"
  fi

  ln -s "$src" "$dest"
  echo "  [linked] $dest → $src"
}

# ---- Windows: copy ----
copy_entry() {
  local src="$1"
  local dest="$2"

  if [[ ! -e "$src" ]]; then
    echo "  [skip]   $dest  (not present in dotfiles)"
    return
  fi

  if [[ -d "$src" ]]; then
    mkdir -p "$dest"
    cp -R "$src/." "$dest/"
    echo "  [copied dir]  $dest"
  else
    cp -f "$src" "$dest"
    echo "  [copied file] $dest"
  fi
}

if $IS_WINDOWS; then
  echo "Initial copy: dotfiles/claude → ~/.claude ..."
  for entry in "${ENTRIES[@]}"; do
    copy_entry "$CLAUDE_SRC/$entry" "$CLAUDE_DEST/$entry"
  done
  echo "windows" > "$CLAUDE_DEST/.dotfiles-mode"
  echo ""
  echo "Done (Windows copy mode). Use sync.sh going forward — it handles two-way mirror."
else
  echo "Linking ~/.claude → dotfiles/claude ..."
  for entry in "${ENTRIES[@]}"; do
    link "$CLAUDE_SRC/$entry" "$CLAUDE_DEST/$entry"
  done
  echo "unix-symlink" > "$CLAUDE_DEST/.dotfiles-mode"
  echo ""
  echo "Done (Unix symlink mode). All Claude config is symlinked from $CLAUDE_SRC"
fi
