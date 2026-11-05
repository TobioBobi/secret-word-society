#!/usr/bin/env bash
set -euo pipefail
group="${1:-}"
if [[ "$group" != 1 && "$group" != 2 ]]; then
  echo 'Expected Android game test group 1 or 2.' >&2
  exit 1
fi
flutter test integration_test/app_test.dart -d emulator-5554 --reporter expanded --dart-define="GAME_TEST_GROUP=$group"
if [[ "$group" == 2 ]]; then
  flutter test integration_test/photo_pipeline_test.dart -d emulator-5554 --reporter expanded
  flutter build apk --release --target integration_test/photo_release_probe.dart
  bash scripts/check-photo-release.sh build/app/outputs/flutter-apk/app-release.apk emulator-5554
fi
