#!/usr/bin/env bash
# Install OpenCode and this portable config on a fresh Mac.
# Usage: ./install.sh [--dry-run]

set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
STAMP="$(date +%Y%m%d-%H%M%S)"
DRY_RUN=0

[ "${1:-}" = "--dry-run" ] && DRY_RUN=1

say() { printf '%s\n' "$*"; }
run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    say "[dry-run] $*"
  else
    "$@"
  fi
}
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

command -v brew >/dev/null 2>&1 || die "Homebrew required: https://brew.sh"

if command -v opencode >/dev/null 2>&1; then
  say "opencode already installed: $(opencode --version 2>/dev/null || echo unknown)"
else
  say "installing opencode"
  run brew install opencode
fi

run mkdir -p "$DEST/backups"

# Back up anything this script is about to replace.
for f in opencode.json opencode.jsonc cli.json AGENTS.md; do
  if [ -f "$DEST/$f" ]; then
    say "backing up $f"
    run cp "$DEST/$f" "$DEST/backups/$f.$STAMP"
  fi
done

# A legacy opencode.json takes precedence over opencode.jsonc. Move it aside so
# the portable config is the only global config in effect.
if [ -f "$DEST/opencode.json" ]; then
  say "moving legacy opencode.json to backups/"
  run mv "$DEST/opencode.json" "$DEST/backups/opencode.json.$STAMP"
fi

say "installing config into $DEST"
run install -m 0644 "$SRC/opencode.jsonc" "$DEST/opencode.jsonc"
run install -m 0644 "$SRC/cli.json" "$DEST/cli.json"
run install -m 0644 "$SRC/AGENTS.md" "$DEST/AGENTS.md"

cat <<EOF

Done. Config: $DEST

Next steps:
  1. Authenticate providers:      opencode auth login
  2. Export provider keys:        see $SRC/env.example
  3. Start OpenCode and pick:     opencode  →  /models
  4. Verify MCP servers:          opencode mcp list

Rollback: move files back from $DEST/backups/
EOF
