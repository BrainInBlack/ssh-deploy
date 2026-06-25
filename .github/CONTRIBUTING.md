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
- **Run the tests** ([bats](https://github.com/bats-core/bats-core)):
  ```sh
  bats test
  ```
  They stub `ssh`/`scp`, so no network or real host is touched. Add or update a
  test when you change parsing, argument handling, or the deploy flow.
- **Lint the man page** if you touch it:
  ```sh
  mandoc -T lint ssh-deploy.1
  ```

  CI runs ShellCheck and the test suite (on Linux and macOS) on every push and
  pull request.

## Pull requests

- One focused change per PR, with a short description of the why.
- Add a note under `## [Unreleased]` in `CHANGELOG.md`.
- Cover new behavior with a test in `test/ssh-deploy.bats` where practical.
- If you change behavior or flags, keep these in sync: `README.md`, the in-script
  `--help`, and the `ssh-deploy.1` man page (including its `.TH` version line on a
  release).
