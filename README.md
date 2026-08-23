# worktree-githooks

One global hook that runs your repo's setup script when it exists.

Fresh worktrees have the branch's tracked files but not `node_modules` or `.venv`. You still need to rebuild that part. This automates it.

## How it works

Git has no `post-worktree` hook. The one that fires on `git worktree add` is `post-checkout` (`githooks(5)`). Install it once and it stays quiet until a repo opts in.

- global hook: `~/.config/git/hooks/post-checkout` from this repo. It checks one path only: `scripts/worktree-setup.sh`. `scripts/` is tracked so every worktree gets it. `.git/` is not.
- per-repo script: `scripts/worktree-setup.sh` that you commit. See `scripts/worktree-setup.sh.example`. Node reuses the main `node_modules` when `package-lock.json` matches and runs `npm ci` otherwise, Python runs `uv sync`. Stamp-gated so `checkout`/`switch` stays fast when already current.
- no file at that path means the hook exits 0. No cost.

That split is the point. The dispatcher stays generic, the repo owns its setup.

## Install

Global, once:

```bash
mise run install-worktree-githooks
# clones to ~/projects/worktree-githooks, copies the hook to ~/.config/git/hooks/post-checkout, sets git config --global core.hooksPath
```

Per-repo, opt in:

```bash
cp ~/projects/worktree-githooks/scripts/worktree-setup.sh.example scripts/worktree-setup.sh
chmod +x scripts/worktree-setup.sh
# trim to your stack and commit
git add scripts/worktree-setup.sh && git commit -m "chore: add worktree setup"
```

Then:

```bash
git worktree add ../feature -b feature
# post-checkout fires and deps appear
```

## Notes

The hook never blocks checkout. If setup fails it warns and checkout still succeeds.

Want a different path? Change the `candidate=` line in `.githooks/post-checkout` and run `mise run install-worktree-githooks` again.

MIT.
