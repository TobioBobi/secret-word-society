#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
test_dir="$(mktemp -d)"
trap 'rm -rf "$test_dir"' EXIT
mkdir -p "$test_dir/bin" "$test_dir/path with spaces"
# Simulate df at the process boundary; never allocate or delete runner data.
cat > "$test_dir/bin/df" <<'EOF'
#!/usr/bin/env bash
printf 'Filesystem 1024-blocks Used Available Capacity Mounted on\n'
printf 'test 99999999 0 %s 0%% /\n' "$TEST_AVAILABLE_KIB"
EOF
chmod +x "$test_dir/bin/df"
export PATH="$test_dir/bin:$PATH"

export TEST_AVAILABLE_KIB=25165823
if bash scripts/check-android-disk.sh 24 "$test_dir/path with spaces" > "$test_dir/log" 2>&1; then
  echo 'FAIL: insufficient space was accepted' >&2
  exit 1
fi
grep -F 'available 25165823 KiB; required 25165824 KiB (24 GiB)' "$test_dir/log"
grep -F '::error::Insufficient disk space' "$test_dir/log"

export TEST_AVAILABLE_KIB=25165824
bash scripts/check-android-disk.sh 24 "$test_dir/path with spaces"
echo 'Disk guard: shortage rejected, exact threshold accepted.'
