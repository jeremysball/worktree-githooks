#!/usr/bin/env bash
set -euo pipefail
# Legacy per-repo installer — prefer the global `mise run install-worktree-githooks`.
# Copies global dispatchers into .githooks/ and sets core.hooksPath.
ROOT="$(cd "$(dirname "$0")" && pwd)"
DEST=".githooks"
mkdir -p "$DEST"
for hook in post-checkout pre-commit; do
  if [ -f "$ROOT/.githooks/$hook" ]; then
    cp "$ROOT/.githooks/$hook" "$DEST/$hook"
    chmod +x "$DEST/$hook"
    echo "installed $DEST/$hook"
  fi
done
git config core.hooksPath "$DEST"
echo "set core.hooksPath=$DEST"
echo "add scripts/worktree-setup.sh to this repo for worktree setup; emdash check is now global"
