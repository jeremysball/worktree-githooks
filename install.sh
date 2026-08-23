#!/usr/bin/env bash
set -euo pipefail
# Legacy per-repo installer — prefer the global `mise run install-worktree-githooks`.
# Still useful to test the dispatcher locally: copies the global dispatcher into .githooks/
ROOT="$(cd "$(dirname "$0")" && pwd)"
DEST=".githooks"
mkdir -p "$DEST"
cp "$ROOT/.githooks/post-checkout" "$DEST/post-checkout"
chmod +x "$DEST/post-checkout"
git config core.hooksPath "$DEST"
echo "installed $DEST/post-checkout (global dispatcher) and set core.hooksPath=$DEST"
echo "add scripts/worktree-setup.sh to this repo to actually do work on worktree add"
