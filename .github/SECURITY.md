# Security Policy

`ssh-deploy` copies a local script to a remote host and runs it **as root**, so
its own correctness has security weight. Reports are taken seriously.

## Supported versions

The latest release on the `main` branch is supported. Fixes land there first and
ship in the next tagged release.

| Version | Supported |
| ------- | --------- |
| 1.0.x   | ✅        |
| < 1.0   | ❌        |

## Reporting a vulnerability

**Please do not open a public issue for security problems.**

Report privately via either:

- GitHub's [private vulnerability reporting][advisories] — the **"Report a
  vulnerability"** button under the repository's *Security* tab (preferred), or
- email to **braininblack@gmail.com** with `[ssh-deploy security]` in the
  subject.

Please include:

- the `ssh-deploy` version (`ssh-deploy --version`) and how it was invoked,
- your OS / bash version and, if relevant, the target host's environment,
- a description of the issue and its impact, and
- a minimal reproduction or proof of concept if you have one.

You can expect an acknowledgement within **5 business days**. Once the issue is
confirmed, we'll agree on a disclosure timeline with you, prepare a fix, and
credit you in the release notes unless you prefer to stay anonymous.

## Scope

In scope — vulnerabilities **in `ssh-deploy` itself**, for example:

- command, argument, or path injection through filenames, SSH config values,
  targets, or other input the script handles,
- symlink / TOCTOU / temp-file races in how the payload is staged on the target,
- mishandling that could let an unintended script run, or run with more
  privilege than intended.

Out of scope:

- the behavior of the payload script **you** choose to deploy (it runs as root
  by design — review what you deploy),
- weaknesses in OpenSSH, `sudo`, `fzf`, or the operating system,
- a misconfigured `~/.ssh/config` or compromised credentials on your own
  machine or the target host.
