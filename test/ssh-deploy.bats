#!/usr/bin/env bats
#
# Tests for ssh-deploy. No network or real host is touched: `ssh` and `scp` are
# replaced with stubs on PATH that log their args and fake the few responses the
# script needs (remote mktemp + a successful run).

setup() {
  SCRIPT="${BATS_TEST_DIRNAME}/../ssh-deploy"
  TMP="$(mktemp -d)"
  STUB="$TMP/bin"
  mkdir -p "$STUB"

  # Point HOME at the temp dir so the default ~/.ssh/config is reliably absent;
  # tests that need a config pass it explicitly with -c. Keeps the suite hermetic
  # regardless of the developer's real SSH setup.
  export HOME="$TMP"

  export SSHLOG="$TMP/ssh.log"
  : > "$SSHLOG"

  # Stub ssh: log args; if asked to run mktemp on the "remote", print a path.
  cat > "$STUB/ssh" <<'EOS'
#!/usr/bin/env bash
echo "ssh $*" >> "$SSHLOG"
for a in "$@"; do
  case "$a" in *mktemp*) echo "/tmp/ssh-deploy.testXXXX"; exit 0 ;; esac
done
exit 0
EOS

  # Stub scp: just log and succeed.
  cat > "$STUB/scp" <<'EOS'
#!/usr/bin/env bash
echo "scp $*" >> "$SSHLOG"
exit 0
EOS
  chmod +x "$STUB/ssh" "$STUB/scp"

  # Fixture ssh config exercising the parser's edge cases.
  CONFIG="$TMP/config"
  cat > "$CONFIG" <<'EOS'
Host web01 web02
    HostName 10.0.0.5
Host db
    HostName=10.0.0.9
Host *.internal
    HostName 10.0.0.99
EOS

  PAYLOAD="$TMP/payload.sh"
  echo 'echo hi' > "$PAYLOAD"

  # Restricted PATH: our stubs + system dirs, deliberately excluding any dir
  # that holds fzf so the script takes the numbered-menu path deterministically.
  export PATH="$STUB:/usr/bin:/bin:/usr/sbin:/sbin"
}

teardown() {
  rm -rf "$TMP"
}

# --- argument handling -------------------------------------------------------

@test "--version prints name and version" {
  run "$SCRIPT" --version
  [ "$status" -eq 0 ]
  [ "$output" = "ssh-deploy 1.3.0" ]
}

@test "--help shows usage and exits 0" {
  run "$SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"USAGE"* ]]
  [[ "$output" == *"ssh-deploy [options] <payload>"* ]]
}

@test "unknown option exits 2" {
  run "$SCRIPT" --bogus
  [ "$status" -eq 2 ]
  [[ "$output" == *"unknown option"* ]]
}

@test "missing payload exits 2" {
  run "$SCRIPT" --no-color
  [ "$status" -eq 2 ]
}

@test "--target without a value exits 2" {
  run "$SCRIPT" --no-color --target
  [ "$status" -eq 2 ]
}

@test "missing ssh config dies with rc 1" {
  run "$SCRIPT" --no-color -c "$TMP/does-not-exist" payload
  [ "$status" -eq 1 ]
  [[ "$output" == *"no ssh config"* ]]
}

@test "missing payload file dies with rc 1" {
  run "$SCRIPT" --no-color -c "$CONFIG" -t web01 "$TMP/nope.sh"
  [ "$status" -eq 1 ]
  [[ "$output" == *"payload not found"* ]]
}

@test "explicit --config that is missing still dies" {
  run "$SCRIPT" --no-color -c "$TMP/does-not-exist" -t web01 "$PAYLOAD"
  [ "$status" -eq 1 ]
  [[ "$output" == *"no ssh config"* ]]
}

# --- config is optional ------------------------------------------------------

@test "no ssh config: -t still works, and no -F is passed" {
  # HOME has no .ssh/config and no -c given; -t supplies the target.
  run "$SCRIPT" --no-color -y -t myhost "$PAYLOAD"
  [ "$status" -eq 0 ]
  [[ "$output" == *"done on"* ]]
  ! grep -q -- "-F" "$SSHLOG"
}

@test "no ssh config and no -t: prompts for a target" {
  run bash -c "printf 'myhost\n' | '$SCRIPT' --no-color -y '$PAYLOAD'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"enter a target manually"* ]]
  [[ "$output" == *"Target (user@host)"* ]]
  [[ "$output" == *"done on"* ]]
  grep -q "myhost" "$SSHLOG"
  ! grep -q -- "-F" "$SSHLOG"
}

# --- ssh config parser (via the numbered-menu listing) -----------------------

@test "parser lists aliases with their hostnames" {
  run bash -c "printf '0\n' | '$SCRIPT' --no-color -c '$CONFIG' '$PAYLOAD'"
  [ "$status" -eq 1 ]            # '0' is an invalid selection
  [[ "$output" == *"web01"* ]]
  [[ "$output" == *"web02"* ]]
  [[ "$output" == *"db"* ]]
  [[ "$output" == *"10.0.0.5"* ]]
  [[ "$output" == *"10.0.0.9"* ]]   # HostName=... (equals form) parsed
}

@test "parser applies HostName to every alias on a multi-alias Host line" {
  run bash -c "printf '0\n' | '$SCRIPT' --no-color -c '$CONFIG' '$PAYLOAD'"
  echo "$output" | grep -Eq 'web01.*10\.0\.0\.5'
  echo "$output" | grep -Eq 'web02.*10\.0\.0\.5'
}

@test "parser skips wildcard Host entries" {
  run bash -c "printf '0\n' | '$SCRIPT' --no-color -c '$CONFIG' '$PAYLOAD'"
  [[ "$output" != *"internal"* ]]
  [[ "$output" != *"10.0.0.99"* ]]
}

# --- dry-run -----------------------------------------------------------------

@test "dry-run shows the plan and touches nothing" {
  run "$SCRIPT" --no-color -c "$CONFIG" -n -t web01 "$PAYLOAD"
  [ "$status" -eq 0 ]
  [[ "$output" == *"dry-run"* ]]
  [[ "$output" == *"mktemp"* ]]
  [[ "$output" == *"scp -F"* ]]
  [ ! -s "$SSHLOG" ]            # no ssh/scp actually invoked
}

# --- deploy (stubbed ssh/scp) ------------------------------------------------

@test "deploy stages via mktemp, copies, runs, and reports success" {
  run "$SCRIPT" --no-color -c "$CONFIG" -y -t web01 "$PAYLOAD"
  [ "$status" -eq 0 ]
  [[ "$output" == *"copied"* ]]
  [[ "$output" == *"done on"* ]]
  grep -q "mktemp /tmp/ssh-deploy" "$SSHLOG"      # remote temp file created
  grep -q "^scp " "$SSHLOG"                       # payload copied
  grep -q "sudo bash" "$SSHLOG"                    # run as root
}

@test "--config is threaded through to ssh and scp (-F)" {
  run "$SCRIPT" --no-color -y -c "$CONFIG" -t web01 "$PAYLOAD"
  [ "$status" -eq 0 ]
  grep -q -- "-F $CONFIG" "$SSHLOG"
}

@test "remote exit code is propagated" {
  # Make the stubbed remote run fail; ssh-deploy should die with rc 1.
  cat > "$STUB/ssh" <<'EOS'
#!/usr/bin/env bash
echo "ssh $*" >> "$SSHLOG"
for a in "$@"; do
  case "$a" in *mktemp*) echo "/tmp/ssh-deploy.testXXXX"; exit 0 ;; esac
done
for a in "$@"; do
  case "$a" in *"sudo bash"*) exit 7 ;; esac   # remote script failed
done
exit 0
EOS
  chmod +x "$STUB/ssh"
  run "$SCRIPT" --no-color -c "$CONFIG" -y -t web01 "$PAYLOAD"
  [ "$status" -eq 1 ]
  [[ "$output" == *"errors"* ]]
}

# --- multiple targets --------------------------------------------------------

# Stub whose remote run fails only on web01 (mktemp/scp still succeed), so the
# multi-target failure tests can tell stop-on-error from --keep-going.
stub_fail_web01() {
  cat > "$STUB/ssh" <<'EOS'
#!/usr/bin/env bash
echo "ssh $*" >> "$SSHLOG"
for a in "$@"; do case "$a" in *mktemp*) echo "/tmp/ssh-deploy.testXXXX"; exit 0 ;; esac; done
run=0 web01=0
for a in "$@"; do
  case "$a" in *"sudo bash"*) run=1 ;; esac
  case "$a" in web01) web01=1 ;; esac
done
[ "$run" = 1 ] && [ "$web01" = 1 ] && exit 7
exit 0
EOS
  chmod +x "$STUB/ssh"
}

@test "comma-separated -t deploys to every target" {
  run "$SCRIPT" --no-color -c "$CONFIG" -y -t web01,db "$PAYLOAD"
  [ "$status" -eq 0 ]
  [[ "$output" == *"done on"*"web01"* ]]
  [[ "$output" == *"done on"*"db"* ]]
  [[ "$output" == *"all 2 targets succeeded"* ]]
  grep -q -- "-t web01 " "$SSHLOG"
  grep -q -- "-t db "    "$SSHLOG"
}

@test "stop on first error: later targets are not touched" {
  stub_fail_web01
  run "$SCRIPT" --no-color -c "$CONFIG" -y -t web01,db "$PAYLOAD"
  [ "$status" -eq 1 ]
  [[ "$output" == *"finished with errors"*"web01"* ]]
  ! grep -q "db" "$SSHLOG"        # stopped before reaching the second host
}

@test "--keep-going continues past a failure and reports a summary" {
  stub_fail_web01
  run "$SCRIPT" --no-color -c "$CONFIG" -y -k -t web01,db "$PAYLOAD"
  [ "$status" -eq 1 ]
  [[ "$output" == *"continuing"* ]]
  [[ "$output" == *"completed with failures"*"web01"* ]]
  [[ "$output" == *"done on"*"db"* ]]
  grep -q -- "-t db " "$SSHLOG"   # second host was still attempted
}

@test "dry-run with multiple targets lists them and shows the plan once" {
  run "$SCRIPT" --no-color -c "$CONFIG" -n -t web01,db "$PAYLOAD"
  [ "$status" -eq 0 ]
  [[ "$output" == *"web01"* ]]
  [[ "$output" == *"db"* ]]
  [[ "$output" == *"<target>"* ]]        # generic template, not per-target
  [[ "$output" == *"scp -F"* ]]
  [ ! -s "$SSHLOG" ]
}
