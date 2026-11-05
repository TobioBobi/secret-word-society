#!/usr/bin/env bash
set -euo pipefail
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
bash "$script_dir/require-android-test-groups.sh" success
for result in failure cancelled skipped pending ''; do
  if bash "$script_dir/require-android-test-groups.sh" "$result"; then
    echo "Expected Android gate to reject '$result'" >&2
    exit 1
  fi
done
if bash "$script_dir/require-android-test-groups.sh"; then
  echo 'Expected Android gate to reject a missing result' >&2
  exit 1
fi
echo 'Android aggregate gate checks passed.'
