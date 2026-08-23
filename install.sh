#!/usr/bin/env bash
set -euo pipefail
# install worktree-githooks into current repo
# copies .githooks/post-checkout and sets core.hooksPath
ROOT="$(cd "$(dirname "$0")" && pwd)"
DEST=".githooks"
mkdir -p "$DEST"
cp "$ROOT/.githooks/post-checkout" "$DEST/post-checkout"
chmod +x "$DEST/post-checkout"
git config core.hooksPath "$DEST"
echo "installed $DEST/post-checkout and set core.hooksPath=$DEST"
