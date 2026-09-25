#!/usr/bin/env bash
# Import + scene smoke + rule tests. Exit non-zero on any script error or test failure.
set -u
cd "$(dirname "$0")/.."
GODOT="${GODOT:-/c/dev/Godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe}"
fail=0

echo "== import"
out=$(timeout 400 "$GODOT" --headless --editor --path . --quit 2>&1)
if echo "$out" | grep -E "SCRIPT ERROR|Parse Error|^ERROR" ; then fail=1; fi

echo "== scene smoke (headless)"
for s in title combat map; do
	out=$(timeout 120 "$GODOT" --headless --path . "res://scenes/$s.tscn" --quit-after 240 2>&1)
	if echo "$out" | grep -E "SCRIPT ERROR|Parse Error"; then echo "   in scene $s"; fail=1; fi
done

echo "== rule tests"
out=$(timeout 300 "$GODOT" --headless --path . -s res://tests/test_runner.gd 2>&1)
echo "$out" | grep -E "seed|autoplay|passed|FAIL"
if echo "$out" | grep -E "SCRIPT ERROR"; then fail=1; fi
if ! echo "$out" | grep -q "ALL TESTS PASSED"; then fail=1; fi

if [ $fail -ne 0 ]; then echo "CHECKS FAILED"; exit 1; fi
echo "ALL CHECKS PASSED"
