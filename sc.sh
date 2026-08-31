#!/bin/zsh

# Launch an Android app on a desktop-sized scrcpy virtual display.
# Usage: sc.sh [app display name | package name] [scrcpy options]

setopt local_options no_unset pipe_fail

# Treat scrcpy's UHID device as an external keyboard, so Android does not open
# the full on-screen keyboard. Chinese composition is still handled by Sogou.
adb shell settings put secure show_ime_with_hard_keyboard 0 >/dev/null 2>&1
adb shell ime set com.sohu.inputmethod.sogou.xiaomi/.SogouIME >/dev/null 2>&1

app="com.ss.android.lark"
start_app="com.ss.android.lark"
window_title="飞书 Desktop"
display_size="1600x900/220"
window_size_args=(--window-width=1600)
mouse_args=(--mouse=uhid --mouse-bind=bhsn:++++)

# A non-option first argument is an app display name or package name.
if (( $# > 0 )) && [[ "$1" != -* ]]; then
  app="$1"
  shift
  window_title="${app} Desktop"

  case "$app" in
    微信) start_app="com.tencent.mm" ;;
    微信读书) start_app="com.tencent.weread" ;;
    飞书) start_app="com.ss.android.lark" ;;
    抖音) start_app="com.ss.android.ugc.aweme" ;;
    *.*) start_app="$app" ;;
    *)
      # Resolve other names exactly; never use scrcpy's prefix matching.
      start_app="$(command scrcpy --list-apps 2>/dev/null | awk -v target="$app" '
        $1 == "-" {
          package_name = $NF
          app_name = $0
          sub(/^[[:space:]]*-[[:space:]]*/, "", app_name)
          sub(/[[:space:]]+[^[:space:]]+$/, "", app_name)
          if (app_name == target) {
            print package_name
            exit
          }
        }
      ')"
      if [[ -z "$start_app" ]]; then
        print -u2 "sc: 未找到名称完全匹配的应用：$app"
        print -u2 "sc: 请用 scrcpy --list-apps 查看应用名称或直接传入包名"
        exit 1
      fi
      ;;
  esac
fi

print "sc: 启动 $app [$start_app]"

# WeChat's UI thread stops processing key events when Android forces its
# portrait-only activities into landscape. Give it a portrait virtual display
# sized to fit comfortably on a desktop instead.
if [[ "$start_app" == "com.tencent.mm" ]]; then
  display_size="900x1600/220"
  window_size_args=(--window-height=1000)
fi

# Some phone-first apps request portrait mode even on the landscape virtual
# display. Apply package-scoped Android compatibility overrides only while
# scrcpy is running, then restore the defaults on exit.
compat_package=""
compat_changes=()

case "$start_app" in
  com.ss.android.lark)
    compat_package="$start_app"
    compat_changes=(254631730)
    ;;
esac

if (( ${#compat_changes} > 0 )); then
  for change_id in $compat_changes; do
    adb shell am compat enable "$change_id" "$compat_package" >/dev/null 2>&1
  done

  cleanup_compat() {
    for change_id in $compat_changes; do
      adb shell am compat reset "$change_id" "$compat_package" >/dev/null 2>&1
    done
  }
  trap cleanup_compat EXIT HUP INT TERM
fi

# Keep the IME on the virtual display that owns the focused editor. Sending it
# to display 0 (fallback) breaks Sogou hardware-keyboard composition. Android
# still hides the full keyboard via show_ime_with_hard_keyboard=0.
scrcpy_args=(
  --keyboard=uhid
  $mouse_args
  --stay-awake
  --video-codec=h264
  --video-encoder=c2.qti.avc.encoder
  --video-codec-options=low-latency=1
  --video-bit-rate=8M
  --video-buffer=0
  --max-fps=60
  --render-driver=metal
  --fullscreen
  --new-display="$display_size"
  --start-app="$start_app"
  --display-ime-policy=local
  --no-vd-system-decorations
  --no-vd-destroy-content
  $window_size_args
  --window-title="$window_title"
)

command scrcpy "${scrcpy_args[@]}" "$@"
