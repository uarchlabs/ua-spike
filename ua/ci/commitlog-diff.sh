#!/bin/bash
# SPDX-License-Identifier: BSD-3-Clause
# Copyright (c) 2026 Jeff Nye, uarchlabs.com
#
# Run every test binary on two Spike builds with --log-commits and compare
# the exit status and the commit log of each run.
# Usage: commitlog-diff.sh <ua-spike binary> <upstream spike binary> <tests dir> <log dir>
#
# Fails if any test behaves differently on the two builds. A test that fails
# on both is reported but does not fail the check: it is upstream behaviour.
set -uo pipefail

ours=$1
base=$2
tests=$3
logs=$4
ISA=${ISA:-rv64gch_ziccid_zfh_zicboz_svnapot_zicntr_zba_zbb_zbkb_zbkx_zbc_zbs_zicond_zicclsm_zacas_zabha_zalasr}
LIMIT=${LIMIT:-60}

mkdir -p "$logs"
same=0 differ=0 bothfail=0
for t in "$tests"/*; do
  [ -f "$t" ] && [ -x "$t" ] || continue
  n=$(basename "$t")
  isa=$ISA
  case "$n" in hypervisor-svadu-*) isa=${ISA}_svadu ;; esac
  timeout "$LIMIT" "$ours" --isa="$isa" --log-commits --log="$logs/$n.ours" "$t" > /dev/null 2>&1
  ro=$?
  timeout "$LIMIT" "$base" --isa="$isa" --log-commits --log="$logs/$n.base" "$t" > /dev/null 2>&1
  rb=$?
  if [ "$ro" != "$rb" ] || ! cmp -s "$logs/$n.ours" "$logs/$n.base"; then
    echo "DIFFER  $n (exit: ours $ro, upstream $rb)"
    diff "$logs/$n.base" "$logs/$n.ours" | head -5
    differ=$((differ + 1))
  else
    [ "$ro" != 0 ] && { echo "BOTH-FAIL $n (exit $ro)"; bothfail=$((bothfail + 1)); }
    same=$((same + 1))
    rm -f "$logs/$n.ours" "$logs/$n.base"
  fi
done

echo "commit logs: $same identical, $differ different, $bothfail failing on both builds"
[ "$differ" = 0 ] && [ "$same" -gt 0 ]
