# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.2.0] - 2026-06-25

### Added
- Man page `ssh-deploy(1)` — viewable with `man ssh-deploy` once installed (the
  Homebrew formula installs it). Documents options, exit status, files,
  environment, and security notes.
- CI now also runs the test suite on macOS (BSD userland + bash 3.2), alongside
  Linux, to back up the portability claims.

## [1.1.0] - 2026-06-25

### Added
- Test suite ([bats](https://github.com/bats-core/bats-core)) covering the
  SSH-config parser, argument handling, dry-run output, and the deploy flow
  (with stubbed `ssh`/`scp` — no network needed). Runs in CI alongside ShellCheck.

### Changed
- `~/.ssh/config` is now optional. If it's absent and no `--config` is given,
  ssh-deploy skips the picker and prompts for a target (or use `--target`)
  instead of erroring out. An explicit `--config FILE` that doesn't exist is
  still reported as an error, and `-F` is only passed to `ssh`/`scp` when a
  config file actually exists.

## [1.0.0] - 2026-06-25

### Added
- Initial release.
- Host picker from `~/.ssh/config`: fuzzy ([fzf](https://github.com/junegunn/fzf)) with a live
  `ssh -G` preview, or a numbered-menu fallback. `Host` lines with multiple aliases and the
  `Keyword=Value` form are both parsed; wildcard/pattern entries are skipped.
- `--target` to skip the picker, plus manual `user@host` entry.
- `--dry-run`, `--yes`, `--config`, `--no-color`, `--help`, `--version`. `--config` is used both
  for the host picker and for the actual `scp`/`ssh` connection.
- Confirmation step with a deploy plan; colored output that auto-disables when piped / `NO_COLOR`.
- Copies the payload to an atomically-created `mktemp` file under `/tmp` on the target (mode 600 —
  no predictable path or symlink race), runs it via `sudo bash` over a TTY, removes it, and returns
  the remote script's exit code.
- `mktemp` + `scp` + the `sudo` run share a single multiplexed SSH connection, so authentication
  (password / key touch) happens once per deploy.
