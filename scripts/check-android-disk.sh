#!/usr/bin/env bash
set -euo pipefail

minimum_gib="${1:?Usage: check-android-disk.sh <minimum-GiB> <path> [path...]}"
shift
if [[ ! "$minimum_gib" =~ ^[1-9][0-9]*$ ]] || (( $# == 0 )); then
  echo 'Expected a positive minimum in GiB and at least one existing path.' >&2
  exit 1
fi
minimum_kib=$((minimum_gib * 1024 * 1024))
for path in "$@"; do
  # POSIX output keeps the available column stable, including on mounted volumes.
  available_kib="$(df -Pk -- "$path" | awk 'NR == 2 {print $4}')"
  if [[ ! "$available_kib" =~ ^[0-9]+$ ]]; then
    echo "::error::Cannot determine available disk space for $path" >&2
    exit 1
  fi
  echo "Disk space at $path: available $available_kib KiB; required $minimum_kib KiB ($minimum_gib GiB)"
  if (( available_kib < minimum_kib )); then
    echo "::error::Insufficient disk space at $path: available $available_kib KiB; required $minimum_kib KiB ($minimum_gib GiB). Android emulator will not be started." >&2
    exit 1
  fi
done
