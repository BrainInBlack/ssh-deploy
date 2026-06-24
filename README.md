# ssh-deploy

Push a local script to an SSH host — picked from your `~/.ssh/config` — and run it there as **root**, with a confirmation step and clean, colored output.

![License: MIT](https://img.shields.io/badge/license-MIT-blue) ![Bash 3.2+](https://img.shields.io/badge/bash-3.2%2B-1f425f) ![Shellcheck: clean](https://img.shields.io/badge/shellcheck-clean-brightgreen) ![Platforms](https://img.shields.io/badge/platforms-Linux%20%7C%20macOS%20%7C%20BSD%20%7C%20WSL-informational)

## Why

You keep small provisioning / maintenance scripts on your machine and want to run one on a server without copying it across by hand every time. `ssh-deploy` reads your SSH config, lets you fuzzy-pick the host (or pass `--target`), shows exactly what it will do, then `scp`s the script to `/tmp`, runs it with `sudo bash` over a TTY, removes it, and exits with the **script's own exit code**.

## Features

- **Host picker** from `~/.ssh/config` — fuzzy ([fzf](https://github.com/junegunn/fzf)) with a live `ssh -G` preview, or a numbered-menu fallback when fzf isn't installed.
- **Uses your existing SSH setup** — keys, jump hosts, YubiKey/FIDO, ports — nothing to reconfigure. Manual `user@host` always available.
- **Safe by default** — a deploy plan + `y/N` confirm (skip with `-y`), and a `--dry-run` that prints the exact commands without touching anything.
- **Readable output** — colors that auto-disable when piped, on `--no-color`, or when `NO_COLOR` is set.
- **Honest exit codes** — returns the remote script's real exit status, not `rm`'s.
- **Portable** — one self-contained Bash script (3.2+, no GNU-only tools); only `ssh`/`scp` required, `fzf` optional. Runs on Linux, macOS, \*BSD, and WSL.

## Platforms

Runs anywhere with **bash 3.2+** and **OpenSSH** — Linux, macOS, \*BSD, and Windows via **WSL** or Git-Bash. It's written to the lowest common denominator (no bash-4 features, no GNU-only tools), so the single file behaves the same across all of them; `fzf` is optional.

The **target** host just needs `/tmp`, `bash`, `mktemp`, and `sudo` for your SSH user — i.e. any Unix-like server. Deploying to a native Windows host isn't supported (the `sudo bash` model assumes a POSIX target).

## Requirements

- `bash` 3.2+, plus `ssh` and `scp` (OpenSSH).
- Optional: [`fzf`](https://github.com/junegunn/fzf) for the fuzzy picker (`brew install fzf` / `apt install fzf`).
- The target host needs `bash`, `mktemp`, and `sudo` for your SSH user — you'll be prompted for the password (a TTY is allocated for it).

## Install

Drop the single script anywhere on your `PATH`:

```sh
curl -fsSL https://raw.githubusercontent.com/BrainInBlack/ssh-deploy/main/ssh-deploy -o ~/.local/bin/ssh-deploy
chmod +x ~/.local/bin/ssh-deploy
```

or clone and symlink:

```sh
git clone https://github.com/BrainInBlack/ssh-deploy.git
ln -s "$PWD/ssh-deploy/ssh-deploy" ~/.local/bin/ssh-deploy
```

(Make sure `~/.local/bin` is on your `PATH`.)

## Usage

```
ssh-deploy [options] <payload>

ARGUMENTS
  payload              local script to run as root on the target  (required)

OPTIONS
  -t, --target HOST   deploy to this ssh alias / user@host (skip the picker)
  -y, --yes           don't ask for confirmation
  -n, --dry-run       show what would happen; don't copy or run
  -c, --config FILE   ssh config to read (default: ~/.ssh/config)
      --no-color      disable colored output
  -h, --help          show this help
  -V, --version       show version

EXAMPLES
  ssh-deploy setup.sh              # pick a host (fzf/menu), then deploy
  ssh-deploy -t web01 setup.sh     # straight to a known host
  ssh-deploy -n -t web01 setup.sh  # dry-run: show the plan, change nothing
```

## How it works

1. Parse `~/.ssh/config` (or `--config FILE`) for `Host` aliases (wildcard/pattern entries are skipped; `Include` files aren't followed). The same config file is used for the actual `scp`/`ssh` connection.
2. Pick one (fzf preview shows the resolved `ssh -G` hostname/user/port/key) or pass `--target`; manual `user@host` is always an option.
3. Print the deploy plan and ask to confirm (`-y` to skip, `-n` to only preview).
4. Open one shared SSH connection (so the password / key-touch happens **once**), `mktemp` a private file under `/tmp` on the target, and `scp` the payload into it — no predictable name, no symlink/clobber race.
5. `ssh -t <target> "sudo bash <tmpfile>; rm -f <tmpfile>"` — the TTY lets the `sudo` password (and any key touch) work, and the temp copy is always removed.
6. Exit with the remote script's exit code.

## Security

- It runs **your script as root on the remote host** — review what you deploy.
- It authenticates using whatever `~/.ssh/config` specifies for that host. The tool never handles, copies, or stores keys.
- The payload is copied to a private `mktemp` file under `/tmp` on the target (atomic create, mode 600 — no predictable path or symlink race) and removed after the run, even on failure.

## License

MIT © BrainInBlack — see [LICENSE](LICENSE).
