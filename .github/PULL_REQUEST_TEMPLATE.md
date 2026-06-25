<!--
Thanks for contributing to ssh-deploy! Please keep PRs focused — one change per PR.
See CONTRIBUTING.md for the ground rules.
-->

## What & why

<!-- What does this change do, and why? Link any related issue, e.g. "Closes #12". -->

## Type of change

- [ ] Bug fix
- [ ] New feature / option
- [ ] Documentation only
- [ ] Refactor / cleanup (no behavior change)

## Checklist

- [ ] One focused change, with a short description of the why (above).
- [ ] Stays portable: runs on stock macOS bash 3.2 — no `mapfile`/`readarray`, associative arrays, `${var,,}`, or other bash 4+ features.
- [ ] Stays single-file with no new runtime dependencies beyond `ssh`/`scp` (and optional `fzf`).
- [ ] Linted locally — both pass clean:
  ```sh
  bash -n ssh-deploy
  shellcheck ssh-deploy
  ```
- [ ] Added a note under `## [Unreleased]` in `CHANGELOG.md`.
- [ ] If behavior or flags changed, updated `README.md` **and** the in-script `--help` together.

## Testing

<!-- How did you verify this? e.g. `--dry-run` output, a real deploy, the host picker, etc. -->
