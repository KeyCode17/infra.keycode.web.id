#!/usr/bin/env bash
#
# Does GUI automation survive a closed lid?
#
# With caffeine ON (pmset SleepDisabled 1) the machine never sleeps, so every
# CLI workload keeps running — that much is settled. What is NOT settled is
# whether anything needing a real window still works once the built-in panel
# leaves the graphics stack and no external display is attached.
#
# Run the baseline with the lid OPEN first, then the real run with it closed.
# A bare FAIL means nothing on its own: two of these tests already fail on this
# machine for reasons that have nothing to do with the lid, so the only honest
# signal is baseline-vs-closed on the same box.
#
#   ./docs/notes/lid-closed-gui-test.sh baseline   # lid open, starts at once
#   ./docs/notes/lid-closed-gui-test.sh            # close the lid during countdown
#
# The second run prints the comparison. Env knobs:
#   DELAY=<sec>        countdown before the closed run        (default 60)
#   SKIP_EMULATOR=1    skip the Android test (saves ~3 min)

set -uo pipefail

MODE="${1:-closed}"
DELAY="${DELAY:-60}"
SKIP_EMULATOR="${SKIP_EMULATOR:-0}"

PW_CACHE="$HOME/Library/Caches/ms-playwright"
EMULATOR="$HOME/Library/Android/sdk/emulator/emulator"
CDP_PORT=9333
OUT="/tmp/lid-closed-gui-test"
LOG="$OUT/$MODE.log"
RESULT="$OUT/$MODE.result"

CHROME_PID=""
EMU_PID=""

say()    { printf '%s\n' "$*" | tee -a "$LOG"; }
hdr()    { say ""; say "── $* ──"; }
record() { say "  [$1] $3"; printf '%s\t%s\t%s\n' "$2" "$1" "$3" >>"$RESULT"; }

cleanup() {
  [ -n "$CHROME_PID" ] && kill "$CHROME_PID" 2>/dev/null
  if [ -n "$EMU_PID" ]; then
    adb -e emu kill >/dev/null 2>&1
    kill "$EMU_PID" 2>/dev/null
  fi
}
trap cleanup EXIT INT TERM

# Newest installed build of a playwright browser dir, e.g. chromium-1243.
newest() { /bin/ls -d "$PW_CACHE/$1"-* 2>/dev/null | sort -V | tail -1; }

case "$MODE" in
  baseline|closed) ;;
  *) echo "usage: $0 [baseline|closed]" >&2; exit 2 ;;
esac

mkdir -p "$OUT"
: > "$LOG"
: > "$RESULT"

say "lid GUI test — mode=$MODE — $(date '+%Y-%m-%d %H:%M:%S')"

# ── Preflight ────────────────────────────────────────────────────────────────
# Only the closed run needs caffeine: without disablesleep the lid close just
# sleeps the machine and the run would measure nothing at all.
if [ "$MODE" = "closed" ]; then
  if ! /usr/bin/pmset -g | grep -qE 'SleepDisabled[[:space:]]+1'; then
    say ""
    say "ABORT: caffeine is OFF (SleepDisabled 0)."
    say "Closing the lid now would sleep the machine. Press cmd-shift-x, then rerun."
    exit 1
  fi
  say "preflight: caffeine ON (SleepDisabled 1) — machine will stay awake"
  say ""
  say "CLOSE THE LID NOW. Tests start in ${DELAY}s, then take ~1 min (~4 with the emulator)."
  for i in $(seq "$DELAY" -1 1); do
    [ -t 1 ] && printf '\r  starting in %3ds ' "$i"
    sleep 1
  done
  [ -t 1 ] && printf '\r%40s\r' ''
  say "started at $(date '+%H:%M:%S')"
else
  say "baseline run — leave the lid OPEN"
fi

# ── 1. Is any display still attached? ────────────────────────────────────────
hdr "1. display state"
DISPLAY_INFO="$(system_profiler SPDisplaysDataType 2>/dev/null)"
printf '%s\n' "$DISPLAY_INFO" | grep -E 'Display Type|Resolution|Main Display|Online|Connection Type' \
  | sed 's/^ */  /' | tee -a "$LOG"
if printf '%s' "$DISPLAY_INFO" | grep -qE 'Online: *Yes'; then
  record ONLINE display "a display reports Online: Yes"
else
  record OFFLINE display "no display online — graphics stack has no panel"
fi

# ── 2. Can the framebuffer be captured? ──────────────────────────────────────
# Distinguishes two very different failures: macOS refusing for lack of the
# Screen Recording TCC grant (which says nothing about the lid) versus a
# capture that is allowed but comes back empty (which says everything).
hdr "2. screencapture"
SHOT="$OUT/$MODE-screencapture.png"
rm -f "$SHOT"
SC_ERR="$(screencapture -x "$SHOT" 2>&1)"
SC_RC=$?
SZ=$(stat -f%z "$SHOT" 2>/dev/null || echo 0)
if [ "$SC_RC" -eq 0 ] && [ "$SZ" -gt 10000 ]; then
  record PASS screencapture "captured ${SZ} bytes"
elif printf '%s' "$SC_ERR" | grep -qi 'could not create image'; then
  record NOPERM screencapture "denied: $SC_ERR (grant kitty Screen Recording in System Settings)"
else
  record FAIL screencapture "rc=$SC_RC size=${SZ} ${SC_ERR}"
fi

# ── 3. Headless chromium — the control ───────────────────────────────────────
# Expected to pass in both modes; if it ever fails the problem is not the lid.
hdr "3. playwright chromium — headless (control)"
HS_BIN="$(newest chromium_headless_shell)/chrome-headless-shell-mac-arm64/chrome-headless-shell"
if [ -x "$HS_BIN" ]; then
  if "$HS_BIN" --headless --no-sandbox --disable-gpu \
       --dump-dom 'data:text/html,<title>ok</title><h1>lid-test</h1>' \
       >"$OUT/$MODE-headless.html" 2>>"$LOG" \
     && grep -q 'lid-test' "$OUT/$MODE-headless.html"; then
    record PASS headless "rendered DOM without a display"
  else
    record FAIL headless "headless shell did not render (see $LOG)"
  fi
else
  record SKIP headless "no headless shell installed"
fi

# ── 4. Headed chromium — the real question ───────────────────────────────────
# Ask the browser itself, over CDP, whether it has a page target. A browser
# that starts but can never create a window shows up as a live process with a
# reachable CDP endpoint and no page target, so check the target, not the pid.
hdr "4. playwright chromium — HEADED"
CH_BIN="$(newest chromium)/chrome-mac-arm64/Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing"
if [ -x "$CH_BIN" ]; then
  rm -rf "$OUT/chrome-profile"
  "$CH_BIN" \
    --no-first-run --no-default-browser-check --no-sandbox \
    --user-data-dir="$OUT/chrome-profile" \
    --remote-debugging-port="$CDP_PORT" \
    --window-size=1280,800 \
    'data:text/html,<title>lid-test-headed</title>' \
    >>"$LOG" 2>&1 &
  CHROME_PID=$!

  CDP_OK=0
  for _ in $(seq 1 20); do
    sleep 1
    if curl -sf --max-time 2 "http://127.0.0.1:$CDP_PORT/json/version" >"$OUT/$MODE-cdp-version.json" 2>/dev/null; then
      CDP_OK=1; break
    fi
  done

  if ! kill -0 "$CHROME_PID" 2>/dev/null; then
    record FAIL headed "process died on launch"
  elif [ "$CDP_OK" -eq 0 ]; then
    record FAIL headed "alive but CDP never answered on :$CDP_PORT"
  else
    curl -sf --max-time 3 "http://127.0.0.1:$CDP_PORT/json/list" >"$OUT/$MODE-cdp-targets.json" 2>/dev/null
    VER="$(grep -o '"Browser"[^,]*' "$OUT/$MODE-cdp-version.json" 2>/dev/null | cut -d'"' -f4)"
    if grep -q 'lid-test-headed' "$OUT/$MODE-cdp-targets.json" 2>/dev/null; then
      record PASS headed "real page target created ($VER)"
    else
      record FAIL headed "browser up but no page target — no window could be created"
    fi
  fi
  kill "$CHROME_PID" 2>/dev/null; CHROME_PID=""
else
  record SKIP headed "no headed chromium installed"
fi

# ── 5. Android emulator ──────────────────────────────────────────────────────
# -gpu host is the mode that actually wants the host graphics stack. Check the
# AVD's system image first: a missing image makes the emulator exit instantly,
# which would otherwise read exactly like a lid-induced GPU failure.
hdr "5. android emulator (-gpu host)"
if [ "$SKIP_EMULATOR" = "1" ]; then
  record SKIP emulator "SKIP_EMULATOR=1"
elif [ ! -x "$EMULATOR" ]; then
  record SKIP emulator "no emulator binary"
else
  AVD="$("$EMULATOR" -list-avds 2>/dev/null | head -1)"
  if [ -z "$AVD" ]; then
    record SKIP emulator "no AVD configured"
  else
    SYSDIR="$(grep -E '^image\.sysdir\.1=' "$HOME/.android/avd/$AVD.avd/config.ini" 2>/dev/null | cut -d= -f2-)"
    # The emulator resolves system images against ANDROID_SDK_ROOT. On this
    # machine that variable points at the nix androidsdk, which ships no
    # system-images directory, so the emulator exits in under a second — a
    # failure that reads exactly like a lid-induced GPU failure but is not one.
    # Find the root that genuinely holds this AVD's image and use it.
    SDK_ROOT=""
    for cand in "${ANDROID_SDK_ROOT:-}" "${ANDROID_HOME:-}" "$HOME/Library/Android/sdk"; do
      [ -n "$cand" ] && [ -d "$cand/$SYSDIR" ] && { SDK_ROOT="$cand"; break; }
    done
    if [ -z "$SDK_ROOT" ]; then
      record BROKEN emulator "no SDK root holds image '$SYSDIR' for AVD '$AVD' — pre-existing, unrelated to the lid"
    else
      say "  avd: $AVD"
      [ "$SDK_ROOT" != "${ANDROID_SDK_ROOT:-}" ] \
        && say "  note: overriding ANDROID_SDK_ROOT -> $SDK_ROOT (the env one has no system-images)"
      adb start-server >/dev/null 2>&1
      ANDROID_SDK_ROOT="$SDK_ROOT" ANDROID_HOME="$SDK_ROOT" \
        "$EMULATOR" -avd "$AVD" -gpu host -no-snapshot-load -no-audio >>"$LOG" 2>&1 &
      EMU_PID=$!
      BOOTED=0
      for _ in $(seq 1 60); do
        sleep 3
        kill -0 "$EMU_PID" 2>/dev/null || break
        if [ "$(adb -e shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; then
          BOOTED=1; break
        fi
      done
      if [ "$BOOTED" -eq 1 ]; then
        record PASS emulator "booted with -gpu host (egl: $(adb -e shell getprop ro.hardware.egl 2>/dev/null | tr -d '\r'))"
      elif ! kill -0 "$EMU_PID" 2>/dev/null; then
        record FAIL emulator "exited before boot — retry with -gpu swiftshader_indirect"
      else
        record FAIL emulator "never reported boot_completed within 180s"
      fi
      adb -e emu kill >/dev/null 2>&1
      kill "$EMU_PID" 2>/dev/null; EMU_PID=""
    fi
  fi
fi

# ── Comparison ───────────────────────────────────────────────────────────────
# A single run cannot tell a lid-induced failure from one that was already
# there, so the closed run is only meaningful next to the baseline.
say ""
if [ "$MODE" = "closed" ] && [ -s "$OUT/baseline.result" ]; then
  say "── baseline (lid open) vs closed ──"
  printf '  %-14s %-10s %-10s %s\n' TEST OPEN CLOSED VERDICT | tee -a "$LOG"
  while IFS=$'\t' read -r test closed_status _; do
    open_status="$(awk -F'\t' -v t="$test" '$1==t {print $2}' "$OUT/baseline.result")"
    [ -z "$open_status" ] && open_status="-"
    if [ "$open_status" = "$closed_status" ]; then
      verdict="unchanged — lid made no difference"
    else
      verdict="CHANGED by closing the lid"
    fi
    printf '  %-14s %-10s %-10s %s\n' "$test" "$open_status" "$closed_status" "$verdict" | tee -a "$LOG"
  done <"$RESULT"
elif [ "$MODE" = "closed" ]; then
  say "no baseline to compare against — run '$0 baseline' with the lid open first"
else
  say "baseline saved. Now run: $0"
fi

say ""
say "results: $RESULT"
say "log:     $LOG"
