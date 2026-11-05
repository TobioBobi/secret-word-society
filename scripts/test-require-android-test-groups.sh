#!/usr/bin/env bash
set -euo pipefail
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
bash "$script_dir/require-android-test-groups.sh" success success
for result in failure cancelled skipped pending ''; do
  # Expected failures must not create misleading GitHub error annotations.
  if bash "$script_dir/require-android-test-groups.sh" "$result" success 2>/dev/null; then
    echo "Expected Android gate to reject '$result'" >&2
    exit 1
  fi
  if bash "$script_dir/require-android-test-groups.sh" success "$result" 2>/dev/null; then
    echo "Expected Android gate to reject photo probe result '$result'" >&2
    exit 1
  fi
done
if bash "$script_dir/require-android-test-groups.sh" success 2>/dev/null; then
  echo 'Expected Android gate to reject a missing photo probe result' >&2
  exit 1
fi
if bash "$script_dir/require-android-test-groups.sh" 2>/dev/null; then
  echo 'Expected Android gate to reject a missing result' >&2
  exit 1
fi
echo 'Android aggregate gate checks passed.'
