#!/bin/sh

set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
td_log="$repo_root/td-log"
test_root=$(mktemp -d "${TMPDIR:-/tmp}/td-log.XXXXXX")
trap 'rm -rf "$test_root"' EXIT HUP INT TERM
# ai-ide sets AI_PROJECT; start without it so git-based detection is tested.
unset AI_PROJECT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

query() {
  python3 -c 'import sqlite3, sys
for row in sqlite3.connect(sys.argv[1]).execute(sys.argv[2]):
    print("|".join("" if v is None else str(v) for v in row))' "$1" "$2"
}

project="$test_root/my-project"
mkdir -p "$project/sub"
git -C "$project" init -q
db="$test_root/timeline.db"

# Unset TD_TIMELINE_DB: no-op, no file, run still executes and keeps exit code.
(cd "$project" && unset TD_TIMELINE_DB && "$td_log" development --task AIDA-1) \
  || fail "event without TD_TIMELINE_DB must succeed"
[ ! -e "$db" ] || fail "no database expected without TD_TIMELINE_DB"
set +e
(cd "$project" && unset TD_TIMELINE_DB && "$td_log" run test -- sh -c 'exit 3')
code=$?
set -e
[ "$code" = 3 ] || fail "run without TD_TIMELINE_DB must return command exit code, got $code"

export TD_TIMELINE_DB="$db"

# Events: project from git toplevel, optional fields stay NULL.
(cd "$project/sub" && "$td_log" development --task AIDA-1 --agent claude_code --model opus)
(cd "$project" && "$td_log" review --task AIDA-1 --agent codex)
(cd "$project" && "$td_log" estimation)

# Test wrapper: passes output through, pairs test/test_end, propagates exit code.
out=$(cd "$project" && "$td_log" run test --task AIDA-1 -- sh -c 'echo hello; exit 0')
[ "$out" = hello ] || fail "run must pass command output through, got: $out"
set +e
(cd "$project" && "$td_log" run test --task AIDA-1 -- sh -c 'exit 2')
code=$?
set -e
[ "$code" = 2 ] || fail "run must propagate exit code, got $code"

# A linked worktree (triage baseline) is attributed to the main checkout.
git -C "$project" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
git -C "$project" worktree add -q "$test_root/baseline-AIDA-1" HEAD
(cd "$test_root/baseline-AIDA-1" && "$td_log" fix --task AIDA-1)

# AI_PROJECT (set by ai-ide, where every project is /home/src) wins over git detection.
(cd "$test_root/baseline-AIDA-1" && AI_PROJECT=real-name "$td_log" review --task AIDA-1)

got=$(query "$db" "select project, task_key, type, agent, model, exit_code from events order by id")
expected="my-project|AIDA-1|development|claude_code|opus|
my-project|AIDA-1|review|codex||
my-project||estimation|||
my-project|AIDA-1|test|||
my-project|AIDA-1|test_end|||0
my-project|AIDA-1|test|||
my-project|AIDA-1|test_end|||2
my-project|AIDA-1|fix|||
real-name|AIDA-1|review|||"
[ "$got" = "$expected" ] || fail "unexpected rows:
$got"

# Timestamps are set by SQLite, ISO-8601 UTC with milliseconds, non-decreasing.
bad=$(query "$db" "select count(*) from events where ts not glob '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9].[0-9][0-9][0-9]Z'")
[ "$bad" = 0 ] || fail "malformed timestamps: $bad"
unordered=$(query "$db" "select count(*) from events a join events b on b.id = a.id + 1 where b.ts < a.ts")
[ "$unordered" = 0 ] || fail "timestamps must not decrease"
[ "$(query "$db" "pragma journal_mode")" = wal ] || fail "WAL journal mode expected"

# Unknown and wrapper-only types are rejected without writing.
before=$(query "$db" "select count(*) from events")
for bad_type in dev test test_end; do
  if (cd "$project" && "$td_log" "$bad_type" --task AIDA-1) 2>/dev/null; then
    fail "type '$bad_type' must be rejected"
  fi
done
[ "$(query "$db" "select count(*) from events")" = "$before" ] || fail "rejected types must not write"

# Unwritable database: event fails loudly, test wrapper still returns the test result.
export TD_TIMELINE_DB="$test_root/missing-dir/timeline.db"
if (cd "$project" && "$td_log" development --task AIDA-1) 2>/dev/null; then
  fail "unwritable database must fail"
fi
err=$( (cd "$project" && "$td_log" run test -- true) 2>&1 >/dev/null ) \
  || fail "run must return the command exit code when logging fails"
case "$err" in
  *"cannot write"*) ;;
  *) fail "run must report logging failure, got: $err" ;;
esac

echo "td-log: all tests passed"
