#!/usr/bin/env bash
set -euo pipefail

# Run the AOT/R8 photo harness, not the production app or a debug-only test.
apk="${1:?Usage: check-photo-release.sh <probe.apk> [device]}"
device="${2:-emulator-5554}"
package="com.example.secret_word_society"

adb -s "$device" shell svc wifi disable
adb -s "$device" shell svc data disable
adb -s "$device" install -r "$apk"
adb -s "$device" shell am force-stop "$package"
adb -s "$device" logcat -c
trap 'adb -s "$device" shell am force-stop "$package" >/dev/null || true' EXIT
adb -s "$device" shell am start -W -n "$package/.MainActivity"

for ((attempt=0; attempt<60; attempt++)); do
  output="$(adb -s "$device" logcat -d -s flutter ComponentDiscovery AndroidRuntime)"
  if [[ "$output" == *PHOTO_RELEASE_PROBE:FAIL* ]]; then
    printf '%s\n' "$output"
    exit 1
  fi
  if [[ "$output" == *PHOTO_RELEASE_PROBE:PASS* ]]; then
    printf '%s\n' 'Release photo processing passed offline with AOT and R8.'
    exit 0
  fi
  sleep 1
done
printf '%s\n' "$output"
printf '%s\n' 'Release photo probe did not complete.' >&2
exit 1
