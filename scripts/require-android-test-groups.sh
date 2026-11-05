#!/usr/bin/env bash
set -euo pipefail
result="${1:-}"
if [[ "$result" != success ]]; then
  echo "::error::Android game test groups did not all succeed: ${result:-missing}" >&2
  exit 1
fi
photo_result="${2:-}"
if [[ "$photo_result" != success ]]; then
  echo "::error::Android release photo probe did not succeed: ${photo_result:-missing}" >&2
  exit 1
fi
