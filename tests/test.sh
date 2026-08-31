#!/bin/zsh

setopt local_options errexit no_unset pipe_fail

readonly TEST_DIR="${0:A:h}"
readonly PROJECT_DIR="${TEST_DIR:h}"
readonly SC="$PROJECT_DIR/scrcpy-desktop-launcher"
typeset sandbox
typeset mock_bin
typeset command_log
typeset -i passed=0

sandbox="$(mktemp -d "${TMPDIR:-/tmp}/sc-test.XXXXXX")"
mock_bin="$sandbox/bin"
command_log="$sandbox/commands.log"
mkdir -p "$mock_bin"
trap 'rm -rf -- "$sandbox"' EXIT HUP INT TERM

cat > "$mock_bin/adb" <<'MOCK_ADB'
#!/bin/sh
printf 'adb %s\n' "$*" >> "$SC_TEST_LOG"
if [ "$1" = "-s" ]; then
  shift 2
fi
case "$*" in
  get-state) printf '%s\n' "${SC_TEST_DEVICE_STATE:-device}" ;;
  get-serialno) printf '%s\n' 'mock-device' ;;
  'version') printf '%s\n' 'Android Debug Bridge version 1.0.41' ;;
  'shell getprop ro.build.version.release') printf '%s\n' '15' ;;
  'shell pm path '*) printf '%s\n' "package:/data/app/${3}/base.apk" ;;
  'shell settings get secure show_ime_with_hard_keyboard') printf '%s\n' '1' ;;
  'shell settings get secure default_input_method') printf '%s\n' 'com.example.original/.IME' ;;
  'shell ime list -s')
    printf '%s\n' 'com.example.original/.IME'
    printf '%s\n' 'com.sohu.inputmethod.sogou.xiaomi/.SogouIME'
    ;;
esac
MOCK_ADB

cat > "$mock_bin/scrcpy" <<'MOCK_SCRCPY'
#!/bin/sh
printf 'scrcpy %s\n' "$*" >> "$SC_TEST_LOG"
case " $* " in
  *' --version '*)
    printf '%s\n' 'scrcpy 3.3.3'
    exit 0
    ;;
  *' --help '*)
    printf '%s\n' '--new-display --start-app --display-ime-policy'
    printf '%s\n' '--no-vd-system-decorations --no-vd-destroy-content'
    exit 0
    ;;
  *' --list-apps '*)
    printf '%s\n' ' - Example App                  com.example.app'
    exit 0
    ;;
esac
exit "${SC_TEST_SCRCPY_EXIT:-0}"
MOCK_SCRCPY

chmod +x "$mock_bin/adb" "$mock_bin/scrcpy"
export PATH="$mock_bin:$PATH"
export SC_TEST_LOG="$command_log"

fail() {
  print -ru2 -- "not ok - $1"
  exit 1
}

pass() {
  passed+=1
  print -r -- "ok $passed - $1"
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local message="$3"
  [[ "$haystack" == *"$needle"* ]] || fail "$message (missing: $needle)"
}

assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  local message="$3"
  [[ "$haystack" != *"$needle"* ]] || fail "$message (unexpected: $needle)"
}

output="$($SC --help)"
assert_contains "$output" 'Usage:' 'help is available'
pass 'help'

[[ "$($SC --version)" == 'scrcpy-desktop-launcher 1.1.0' ]] || fail 'version is stable'
pass 'version'

output="$($SC --doctor)"
assert_contains "$output" 'status:  ready' 'doctor validates scrcpy capabilities'
pass 'doctor'

: > "$command_log"
SC_IME='' $SC --dry-run > "$sandbox/output"
output="$(<"$sandbox/output")"
assert_contains "$output" '--start-app=com.ss.android.lark' 'default app is Lark'
assert_contains "$output" '--new-display=1600x900/220' 'default display is landscape'
assert_not_contains "$output" 'c2.qti.avc.encoder' 'encoder is portable by default'
pass 'portable default command'

: > "$command_log"
SC_IME='' $SC --dry-run 微信 --no-audio > "$sandbox/output"
output="$(<"$sandbox/output")"
assert_contains "$output" '--start-app=com.tencent.mm' 'WeChat alias resolves'
assert_contains "$output" '--new-display=900x1600/220' 'WeChat uses portrait display'
assert_contains "$output" '--no-audio' 'scrcpy options pass through'
pass 'WeChat profile and passthrough'

: > "$command_log"
SC_IME='' $SC --serial emulator-5554 --dry-run com.example.app > /dev/null
command_output="$(<"$command_log")"
assert_contains "$command_output" 'adb -s emulator-5554 get-state' 'ADB receives serial'
pass 'device selection'

: > "$command_log"
$SC 飞书 > /dev/null
command_output="$(<"$command_log")"
assert_contains "$command_output" 'settings put secure show_ime_with_hard_keyboard 0' 'keyboard setting changes'
assert_contains "$command_output" 'ime set com.sohu.inputmethod.sogou.xiaomi/.SogouIME' 'configured IME is selected'
assert_contains "$command_output" 'ime set com.example.original/.IME' 'original IME is restored'
assert_contains "$command_output" 'settings put secure show_ime_with_hard_keyboard 1' 'keyboard setting is restored'
assert_contains "$command_output" 'am compat reset 254631730 com.ss.android.lark' 'compatibility change is reset'
pass 'device state cleanup'

: > "$command_log"
set +e
SC_TEST_SCRCPY_EXIT=23 $SC --no-ime 微信 > /dev/null
exit_code=$?
set -e
(( exit_code == 23 )) || fail 'scrcpy exit status is preserved'
command_output="$(<"$command_log")"
assert_contains "$command_output" 'settings put secure show_ime_with_hard_keyboard 1' 'cleanup runs after failure'
pass 'failure status and cleanup'

: > "$command_log"
SC_IME='' $SC --dry-run 'Example App' > "$sandbox/output"
output="$(<"$sandbox/output")"
assert_contains "$output" '--start-app=com.example.app' 'display name resolves exactly'
pass 'exact app name resolution'

print -r -- "1..$passed"
