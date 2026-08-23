# worktree-githooks

A small `post-checkout` hook for git worktrees.

Fresh worktrees have the branch's tracked files, but not untracked deps like `node_modules` or `.venv`. This hook fills that gap: Node reuses the main checkout's `node_modules` when `package-lock.json` matches (otherwise `npm ci`), Python runs `uv sync --locked`. Nothing fancy, just what you'd do by hand.

Git has no `post-worktree` hook — `post-checkout` is the one that fires on `git worktree add` (`githooks(5)`). It also fires on every `checkout`/`switch`, so this hook checks a stamp (`node_modules/.worktree-setup-stamp`) and exits in milliseconds when deps are already current.

## Install

Per-repo (recommended):

```bash
git clone https://github.com/jeremysball/worktree-githooks /tmp/worktree-githooks
cp /tmp/worktree-githooks/.githooks/post-checkout .githooks/post-checkout
chmod +x .githooks/post-checkout
git config core.hooksPath .githooks
```

Or one-liner:

```bash
bash /tmp/worktree-githooks/install.sh
```

Global:

```bash
mkdir -p ~/.config/git/hooks
cp .githooks/post-checkout ~/.config/git/hooks/post-checkout
git config --global core.hooksPath ~/.config/git/hooks
```

Or with mise (dotfiles):

```bash
mise-sys install-worktree-githooks   # clones template to ~/.config/git/hooks + sets global hooksPath
```

Then:

```bash
git worktree add ../feature -b feature
ls -l node_modules   # symlink to main when lockfiles match
```

## Notes

- Node: `npm` + `package-lock.json` only. Python: `uv` + `uv.lock` only. Others are no-ops.
- Hook never blocks checkout — if setup fails it warns and exits 0. Run `npm ci` or `uv sync --locked` by hand if needed.
- Pairs with `scaffolding-repos` (`mise run setup`) and `taskferry` — same symlink logic, just automatic.

MIT.
