#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK="$ROOT/assets/templates/.hooks/stop-doccheck.sh"

command -v jq >/dev/null 2>&1 || {
  echo "FAIL: jq is required" >&2
  exit 1
}
[ -x "$HOOK" ] || {
  echo "FAIL: hook is not executable: $HOOK" >&2
  exit 1
}

cd "$ROOT"
nonce="$$-$(date +%s)"
test_root="$(mktemp -d "${TMPDIR:-/tmp}/project-flow-stop-hook-test.XXXXXX")"
fake_bin="$test_root/bin"
no_jq_bin="$test_root/no-jq-bin"
minimal_bin="$test_root/minimal-bin"
empty_bin="$test_root/empty-bin"
probe_bin="$test_root/probe-bin"
command_log="$test_root/commands.log"
marker_root="/tmp/project-flow-stopcheck-${UID}"
markers=""
mkdir -p "$fake_bin" "$no_jq_bin" "$minimal_bin" "$empty_bin" "$probe_bin"

cat > "$fake_bin/codex" <<'CODEX'
#!/bin/sh
printf 'codex\n' >> "$PROJECT_FLOW_TEST_COMMAND_LOG"
printf 'codex-cli %s\n' "${PROJECT_FLOW_FAKE_CODEX_VERSION:-0.145.0}"
CODEX
chmod +x "$fake_bin/codex"
for command_name in cat; do
  ln -s "$(command -v "$command_name")" "$no_jq_bin/$command_name"
done
for command_name in cat jq mkdir; do
  ln -s "$(command -v "$command_name")" "$minimal_bin/$command_name"
done
# Every external command used by either the old or current hook is a trap.
# Codex must return before even trying to read/parse stdin or inspect its version.
for command_name in cat jq codex awk mkdir tr id; do
  cat > "$probe_bin/$command_name" <<'PROBE'
#!/bin/sh
printf '%s\n' "$0" >> "$PROJECT_FLOW_TEST_COMMAND_LOG"
exit 99
PROBE
  chmod +x "$probe_bin/$command_name"
done

marker_for() {
  local tool="$1" session="$2" scope="$3"
  printf '%s/%s-%s-%s-%s-%s' \
    "$marker_root" "$tool" "${#session}" "$session" "${#scope}" "$scope"
}
remember_marker() {
  local marker="$1"
  markers="${markers}
${marker}"
  rmdir "$marker" 2>/dev/null || true
}
cleanup() {
  printf '%s\n' "$markers" | while IFS= read -r marker; do
    [ -n "$marker" ] && rmdir "$marker" 2>/dev/null || true
  done
  rm -rf "$test_root"
}
trap cleanup EXIT

run_raw() {
  local tool="$1" version="$2" payload="$3"
  printf '%s' "$payload" |
    env PATH="$fake_bin:$PATH" PROJECT_FLOW_FAKE_CODEX_VERSION="$version" \
      PROJECT_FLOW_TEST_COMMAND_LOG="$command_log" /bin/bash "$HOOK" "$tool"
}
run_hook() {
  local tool="$1" active="$2" session="$3" scope="$4"
  local version="${5:-0.145.0}" scope_field
  if [ "$tool" = codex ]; then scope_field=turn_id; else scope_field=prompt_id; fi
  run_raw "$tool" "$version" \
    "{\"session_id\":\"$session\",\"$scope_field\":\"$scope\",\"stop_hook_active\":$active}"
}
assert_block() {
  [ "$#" -eq 1 ] || { echo "FAIL: malformed block assertion arguments" >&2; exit 1; }
  printf '%s' "$1" | jq -e '
    .decision == "block"
    and (.reason | contains("收工自检"))
    and (.reason | contains("CLAUDE.md"))
    and (.reason | contains("业务专项收工检查"))
    and (.reason | contains("Hook 所属项目根"))
  ' >/dev/null
}
assert_continue() {
  [ "$#" -eq 1 ] || { echo "FAIL: malformed continue assertion arguments" >&2; exit 1; }
  [ "$1" = '{"continue":true}' ] || {
    echo "FAIL: expected only {\"continue\":true}; got: $1" >&2
    exit 1
  }
}
assert_no_marker() {
  [ ! -e "$1" ] || {
    echo "FAIL: Codex created a marker: $1" >&2
    exit 1
  }
}
assert_no_commands() {
  [ ! -s "$command_log" ] || {
    echo "FAIL: Codex invoked an external command:" >&2
    cat "$command_log" >&2
    exit 1
  }
}

# Codex has one contract, independent of versions, sessions and Stop state.
version_index=0
for version in 0.144.1 0.145.0 1.0.0 unknown ''; do
  version_index=$((version_index + 1))
  session="codex-session-${version_index}-${nonce}"
  for scope_suffix in first second active-first; do
    scope="codex-${scope_suffix}-${nonce}"
    marker="$(marker_for codex "$session" "$scope")"
    remember_marker "$marker"
    for active in true false false false; do
      assert_continue "$(run_hook codex "$active" "$session" "$scope" "$version")"
      assert_no_marker "$marker"
    done
  done
done
for payload in '' 'not-json' '[]' '42' \
  '{"session_id":"missing-scope"}' \
  '{"turn_id":"missing-session"}' \
  '{"session_id":42,"turn_id":"t"}' \
  '{"session_id":"s","turn_id":{}}' \
  '{"session_id":"unsafe/session","turn_id":"unsafe-turn"}' \
  '{"session_id":"s","prompt_id":"wrong-tool-scope"}'; do
  assert_continue "$(run_raw codex unknown "$payload")"
done
for command_path in "$no_jq_bin" "$empty_bin" "$probe_bin"; do
  codex_error="$test_root/codex-stderr"
  output="$(
    printf '%s' '{"session_id":"s","turn_id":"t","stop_hook_active":false}' |
      env PATH="$command_path" PROJECT_FLOW_TEST_COMMAND_LOG="$command_log" \
        /bin/bash "$HOOK" codex 2> "$codex_error"
  )"
  assert_continue "$output"
  [ ! -s "$codex_error" ] || {
    echo "FAIL: Codex wrote stderr when dependencies were absent or trapped" >&2
    cat "$codex_error" >&2
    exit 1
  }
done
assert_no_commands

# An unread FIFO proves the hook does not block awaiting stdin. A read or cat
# would hang until the bounded watchdog closes this particular test process.
mkfifo "$test_root/stdin-fifo"
exec 3<> "$test_root/stdin-fifo"
env PATH="$empty_bin" /bin/bash "$HOOK" codex <&3 \
  > "$test_root/early-output" 2> "$test_root/early-error" &
early_pid=$!
for _ in 1 2 3 4 5 6 7 8 9 10; do
  kill -0 "$early_pid" 2>/dev/null || break
  sleep 0.1
done
if kill -0 "$early_pid" 2>/dev/null; then
  kill "$early_pid" 2>/dev/null || true
  wait "$early_pid" 2>/dev/null || true
  exec 3>&-
  echo "FAIL: Codex waited for stdin before returning" >&2
  exit 1
fi
wait "$early_pid"
exec 3>&-
printf '%s\n' '{"continue":true}' > "$test_root/expected-output"
cmp "$test_root/expected-output" "$test_root/early-output"
[ ! -s "$test_root/early-error" ]

# Claude retains one continuation per prompt, including active-first recovery.
session="claude-session-${nonce}"
first_scope="claude-first-${nonce}"
first_marker="$(marker_for claude "$session" "$first_scope")"
remember_marker "$first_marker"
assert_block "$(run_hook claude false "$session" "$first_scope")"
[ -d "$first_marker" ]
assert_continue "$(run_hook claude true "$session" "$first_scope")"
[ -d "$first_marker" ]
for _ in 1 2 3; do
  assert_continue "$(run_hook claude false "$session" "$first_scope")"
done
second_scope="claude-second-${nonce}"
remember_marker "$(marker_for claude "$session" "$second_scope")"
assert_block "$(run_hook claude false "$session" "$second_scope")"
active_scope="claude-active-first-${nonce}"
active_marker="$(marker_for claude "$session" "$active_scope")"
remember_marker "$active_marker"
assert_continue "$(run_hook claude true "$session" "$active_scope")"
[ -d "$active_marker" ]
assert_continue "$(run_hook claude false "$session" "$active_scope")"

shared_scope="shared-scope-${nonce}"
for session in "session-a-${nonce}" "session-b-${nonce}"; do
  remember_marker "$(marker_for claude "$session" "$shared_scope")"
  assert_block "$(run_hook claude false "$session" "$shared_scope")"
done
for pair in "a-b:c-collision-${nonce}" "a:b-c-collision-${nonce}"; do
  session="${pair%%:*}"
  scope="${pair#*:}"
  remember_marker "$(marker_for claude "$session" "$scope")"
  assert_block "$(run_hook claude false "$session" "$scope")"
done
cross_session="cross-tool-session-${nonce}"
cross_scope="cross-tool-scope-${nonce}"
remember_marker "$(marker_for claude "$cross_session" "$cross_scope")"
codex_cross_marker="$(marker_for codex "$cross_session" "$cross_scope")"
remember_marker "$codex_cross_marker"
assert_continue "$(run_hook codex false "$cross_session" "$cross_scope")"
assert_block "$(run_hook claude false "$cross_session" "$cross_scope")"
assert_continue "$(run_hook codex true "$cross_session" "$cross_scope")"
assert_no_marker "$codex_cross_marker"

pwd_session="pwd-session-${nonce}"
pwd_scope="pwd-scope-${nonce}"
remember_marker "$(marker_for claude "$pwd_session" "$pwd_scope")"
mkdir -p "$test_root/pwd-a" "$test_root/pwd-b"
assert_block "$(cd "$test_root/pwd-a"; run_hook claude false "$pwd_session" "$pwd_scope")"
assert_continue "$(cd "$test_root/pwd-b"; run_hook claude false "$pwd_session" "$pwd_scope")"

wrong_session="claude-wrong-session-${nonce}"
wrong_scope="claude-wrong-turn-${nonce}"
wrong_marker="$(marker_for claude "$wrong_session" "$wrong_scope")"
remember_marker "$wrong_marker"
wrong_payload="{\"session_id\":\"$wrong_session\",\"turn_id\":\"$wrong_scope\"}"
assert_continue "$(run_raw claude unknown "$wrong_payload")"
[ ! -e "$wrong_marker" ] || {
  echo "FAIL: Claude accepted turn_id instead of required prompt_id" >&2
  exit 1
}
for payload in '' 'not-json' '[]' '42' \
  '{"session_id":"missing-scope"}' \
  '{"prompt_id":"missing-session"}' \
  '{"session_id":42,"prompt_id":"p"}' \
  '{"session_id":"s","prompt_id":{}}' \
  '{"session_id":"s","prompt_id":""}' \
  '{"session_id":"unsafe/session","prompt_id":"unsafe-prompt"}'; do
  assert_continue "$(run_raw claude unknown "$payload")"
done
assert_continue "$(
  printf '%s' '{"session_id":"s","prompt_id":"p","stop_hook_active":false}' |
    env PATH="$no_jq_bin" /bin/bash "$HOOK" claude
)"
minimal_session="minimal-session-${nonce}"
minimal_scope="minimal-prompt-${nonce}"
minimal_marker="$(marker_for claude "$minimal_session" "$minimal_scope")"
remember_marker "$minimal_marker"
minimal_payload="{\"session_id\":\"$minimal_session\",\"prompt_id\":\"$minimal_scope\",\"stop_hook_active\":false}"
assert_block "$(
  printf '%s' "$minimal_payload" |
    env PATH="$minimal_bin" /bin/bash "$HOOK" claude
)"
[ -d "$minimal_marker" ]
assert_continue "$(run_raw unknown unknown '{}')"

for tool in codex claude; do
  concurrent_session="${tool}-concurrent-session-${nonce}"
  concurrent_scope="${tool}-concurrent-scope-${nonce}"
  concurrent_marker="$(marker_for "$tool" "$concurrent_session" "$concurrent_scope")"
  remember_marker "$concurrent_marker"
  for index in 1 2 3 4 5 6 7 8; do
    run_hook "$tool" false "$concurrent_session" "$concurrent_scope" \
      > "$test_root/$tool-concurrent-$index.json" &
  done
  wait
  block_count="$(jq -s '[.[] | select(.decision == "block")] | length' "$test_root/$tool"-concurrent-*.json)"
  continue_count="$(jq -s '[.[] | select(. == {continue:true})] | length' "$test_root/$tool"-concurrent-*.json)"
  if [ "$tool" = claude ]; then
    [ "$block_count" -eq 1 ] && [ "$continue_count" -eq 7 ] || {
      echo "FAIL: concurrent Claude Stop expected 1 block and 7 continue; got $block_count/$continue_count" >&2
      exit 1
    }
  else
    [ "$block_count" -eq 0 ] && [ "$continue_count" -eq 8 ] || {
      echo "FAIL: concurrent Codex Stop expected 8 continue-only replies; got $block_count/$continue_count" >&2
      exit 1
    }
    assert_no_marker "$concurrent_marker"
  fi
done
assert_no_commands

echo "PASS: Codex silent continue-only and Claude Code single-continuation behavior"
