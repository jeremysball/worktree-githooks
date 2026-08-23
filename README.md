# worktree-githooks

`post-checkout` githooks for `git worktree` deps — Node (`node_modules` symlink) + Python (`uv sync`) — gated so they’re cheap on every `checkout`/`switch`, not just `worktree add`.

## Why

Git has **no dedicated `post-worktree` hook**. The only hook that fires on `git worktree add` is `post-checkout` (`githooks(5)`):

> *It is also run after git-clone(1)... Likewise for git worktree add unless --no-checkout is used.*

That hook also fires on **every** `git checkout`/`git switch`, so a naïve `npm ci`/`uv sync` there would run on every branch switch. These hooks gate on lockfile hash + stamp so the common case is a ~5ms no-op.

Behavior mirrors `taskferry`’s `scripts/mise-setup-deps.sh` but as installable githooks rather than a daemon or `mise` hook.

## What it does

- **Node/TS/JS** (`post-checkout:10`): if `package-lock.json` exists — hash it, compare to `node_modules/.worktree-setup-stamp`, skip if identical. Otherwise:
  - main checkout (`main_root == repo_root`): `npm ci`
  - worktree with identical lockfile to main checkout + main has `node_modules`: `ln -s $main_root/node_modules node_modules` (fast-path, same as `mise-setup-deps.sh:50`)
  - else: `npm ci` in this worktree (isolated deps when lockfiles differ)
- **Python** (`post-checkout:22`): if `uv.lock` exists — `uv sync --locked` (idempotent; no symlink — venv is per-worktree)

Both skip entirely when flag `≠ 1` (file checkout) and never fail the checkout (hooks exit 0 on setup failure, warning to stderr).

## Install

Single repo (recommended — `core.hooksPath` → one dir):

```bash
git clone https://github.com/jeremysball/worktree-githooks /tmp/worktree-githooks
cp /tmp/worktree-githooks/hooks/post-checkout .githooks/post-checkout
chmod +x .githooks/post-checkout
git config core.hooksPath .githooks   # per-repo
# or: git config --global core.hooksPath ~/.config/git/hooks  + copy there
```

Polyglot repos — same file handles both ecosystems (no separate hook per language).

Verify:

```bash
git worktree add ../my-feature -b my-feature
# → post-checkout auto-runs: symlink or npm ci, then uv sync if applicable
ls -l node_modules   # symlink → main checkout when lockfiles match
```

## Cost on every checkout

`post-checkout` runs on every branch switch by spec, so the stamp/hashes matter:

- stamp hit (`node_modules/.worktree-setup-stamp == sha256(package-lock.json)`): exits immediately, no `npm ci`
- Node worktree with matching lockfile: single `cmp -s` + `ln -s` (~10ms)
- Only lockfile-differing worktrees pay a real `npm ci`

This keeps `git switch` cheap while still auto-populating fresh worktrees.

## Relationship to `mise` + `taskferry`

- `taskferry`/`scaffolding-repos` use `mise run setup` + `[hooks].enter` (needs `mise activate`, doesn’t fire in `bwrap`). That stays the **explicit** path: `mise run setup && taskferry dispatch`.
- This repo is the **automatic** alternative when you want fresh worktrees to self-populate without remembering `mise run setup`. It deliberately does not use `mise` — pure `bash` + `git rev-parse --git-common-dir`, no hardcoded paths, works from main checkout, any `.claude/worktrees/*`, or throwaway clone.

See `scaffolding-repos/resources/node.md` and `resources/python.md` for the `mise`-based scaffolding these hooks complement, and `taskferry/docs/worktree-dependencies.md` for the full trade-off discussion.

## Limitations

- Node: `npm` + `package-lock.json` only (no pnpm/yarn). Add your package manager’s equivalent behind the same stamp gate if needed.
- Python: `uv` + `uv.lock` only.
- Hook never blocks checkout — setup failure warns to stderr and exits 0. Run `npm ci`/`uv sync --locked` manually if auto-setup failed.
