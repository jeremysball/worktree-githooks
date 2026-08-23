# worktree-githooks

A tiny global `post-checkout` hook that calls your repo's `scripts/worktree-setup.sh` when it exists.

Fresh worktrees have the branch's tracked files but not untracked deps like `node_modules` or `.venv`. This repo solves that without putting logic in the hook itself.

## How it works

Git has no `post-worktree` hook. The one that fires on `git worktree add` is `post-checkout` (`githooks(5)`). Install that hook once globally — it does nothing until a repo opts in.

- Global hook: `~/.config/git/hooks/post-checkout` (from this repo). Hard-coded to one tracked path, no config:
  `scripts/worktree-setup.sh` — because `scripts/` is tracked and every worktree gets it via checkout. `.git/` is untracked, so a hook stored there never reaches a new worktree.
- Per-repo script: `scripts/worktree-setup.sh` (commit it). Example at `scripts/worktree-setup.sh.example` — Node reuses main `node_modules` when `package-lock.json` matches (otherwise `npm ci`), Python runs `uv sync`. Gated on a stamp so every `checkout`/`switch` is milliseconds when already current.
- No file at that path → hook exits 0, no cost. One global install, per-repo opt-in, no configuration.

Idiomatic Git: `core.hooksPath` points to the hook directory. Global `core.hooksPath` handles the dispatcher; per-repo `scripts/worktree-setup.sh` holds the repo-specific setup. No `git config` key for the path itself — one hard-coded path keeps it simple.

## Install

Global (once):

```bash
mise run install-worktree-githooks
# clones this repo to ~/projects/worktree-githooks, copies hook to ~/.config/git/hooks/post-checkout, sets git config --global core.hooksPath
```

Per-repo opt-in:

```bash
cp ~/projects/worktree-githooks/scripts/worktree-setup.sh.example scripts/worktree-setup.sh
chmod +x scripts/worktree-setup.sh
# edit to match your stack (Node, Python, both, or delete a section)
git add scripts/worktree-setup.sh && git commit -m "chore: add worktree setup"
```

Then:

```bash
git worktree add ../feature -b feature
# → post-checkout fires → calls scripts/worktree-setup.sh → deps appear
ls -l node_modules   # symlink to main when lockfiles match
```

## Notes

- Hook never blocks checkout — setup failure warns and the checkout still succeeds.
- Pairs with `scaffolding-repos` (`mise run setup` fallback) — same symlink logic, just automatic now.
- Want a different path? Edit the one line in `.githooks/post-checkout` (`candidate=...`) and reinstall via `mise run install-worktree-githooks`.

MIT.
