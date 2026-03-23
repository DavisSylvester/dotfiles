#!/usr/bin/env bash
# install.sh — dotfiles symlink installer
# Works on macOS and Windows (Git Bash with Developer Mode enabled)
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_SRC="$DOTFILES_DIR/claude"

# Resolve home directory cross-platform
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
  HOME_DIR="$(cygpath -u "$USERPROFILE")"
else
  HOME_DIR="$HOME"
fi

CLAUDE_DEST="$HOME_DIR/.claude"

echo "Dotfiles dir : $DOTFILES_DIR"
echo "Claude source: $CLAUDE_SRC"
echo "Claude dest  : $CLAUDE_DEST"
echo ""

# Ensure destination exists
mkdir -p "$CLAUDE_DEST"

# ---------------------------------------------------------------
# link_file <src> <dest>
# Backs up existing file/dir then creates symlink
# ---------------------------------------------------------------
link() {
  local src="$1"
  local dest="$2"

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

echo "Linking ~/.claude files..."
link "$CLAUDE_SRC/CLAUDE.md"  "$CLAUDE_DEST/CLAUDE.md"
link "$CLAUDE_SRC/mcp.json"   "$CLAUDE_DEST/mcp.json"
link "$CLAUDE_SRC/docs"       "$CLAUDE_DEST/docs"
link "$CLAUDE_SRC/skills"     "$CLAUDE_DEST/skills"

echo ""
echo "Done. All Claude config is now symlinked from:"
echo "  $CLAUDE_SRC"
