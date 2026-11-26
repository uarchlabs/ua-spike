#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2026 Jeff Nye, uarchlabs.com
#
# Build the riscv-tests RV64 ISA tests at a pinned commit.
# Usage: build-riscv-tests.sh <work dir>
# Leaves the test binaries in <work dir>/isa.
set -euo pipefail

RISCV_TESTS_COMMIT=1b3f8bd665d79e5985753a558dae4e3718e2edc8
PREFIX=${RISCV_PREFIX:-riscv64-linux-gnu-}

work=$1
mkdir -p "$work"
work=$(realpath "$work")
src=$work/riscv-tests
out=$work/isa

if [ ! -d "$src/.git" ]; then
  git clone -q https://github.com/riscv-software-src/riscv-tests.git "$src"
fi
git -C "$src" fetch -q origin "$RISCV_TESTS_COMMIT"
git -C "$src" checkout -q "$RISCV_TESTS_COMMIT"
git -C "$src" submodule update -q --init --recursive

rm -rf "$out"
mkdir -p "$out"
cd "$out"
# A Linux cross-compiler builds PIE by default; the tests need fixed addresses.
# It also has no soft-float (lp64) C headers, so the few -mabi=lp64 tests in
# the virtual-memory environment do not build; -k skips them and keeps the rest.
make -k -f "$src/isa/Makefile" src_dir="$src/isa" XLEN=64 \
  RISCV_PREFIX="$PREFIX" \
  RISCV_GCC_OPTS="-static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -fno-pie -no-pie -Wl,--no-warn-rwx-segments" \
  -j"$(nproc)" > "$work/riscv-tests-build.log" 2>&1 || true
rm -f ./*.dump
built=$(ls | wc -l)
skipped=$(grep -c '^make: \*\*\*.*Error' "$work/riscv-tests-build.log" || true)
echo "$built tests built from riscv-tests ${RISCV_TESTS_COMMIT:0:7}, $skipped targets skipped (see riscv-tests-build.log)"
[ "$built" -ge "${MIN_TESTS:-300}" ]
