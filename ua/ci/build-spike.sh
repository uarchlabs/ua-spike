#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2026 Jeff Nye, uarchlabs.com
#
# Build and install Spike from a source tree.
# Usage: build-spike.sh <source dir> <build dir> <install prefix>
set -euo pipefail

src=$(realpath "$1")
build=$2
prefix=$3

if [ ! -f "$src/berkeley-softfloat-3/source/include/softfloat.h" ]; then
  echo "error: $src is missing the berkeley-softfloat-3 submodule" >&2
  echo "       run: git -C $src submodule update --init --recursive" >&2
  exit 1
fi

rm -rf "$build"
mkdir -p "$build" "$prefix"
prefix=$(realpath "$prefix")
cd "$build"
"$src/configure" --prefix="$prefix" > configure.log
make -j"$(nproc)" > make.log
make install > install.log
"$prefix/bin/spike" -h 2>&1 | head -1
