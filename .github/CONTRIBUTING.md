# Contributing

Thanks for your interest in improving `ssh-deploy`!

## Ground rules

- **Stay portable.** The script must run on the stock macOS `bash` (3.2). Avoid `mapfile`/`readarray`,
  associative arrays, `${var,,}`, and other bash 4+ features.
- **Keep it single-file.** `ssh-deploy` is one self-contained script with no runtime dependencies
  beyond `ssh`/`scp` (and optional `fzf`).
- **Lint before you push:**
  ```sh
  bash -n ssh-deploy
  shellcheck ssh-deploy
  ```
  CI runs ShellCheck on every push and pull request.

## Pull requests

- One focused change per PR, with a short description of the why.
- Add a note under `## [Unreleased]` in `CHANGELOG.md`.
- If you change behavior or flags, update `README.md` and the in-script `--help` together.
