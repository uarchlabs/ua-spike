<!-- SPDX-License-Identifier: BSD-3-Clause                     -->
<!-- Copyright (c) 2026 Jeff Nye, uarchlabs.com                -->
# ua-spike

ua-spike is [Spike](https://github.com/riscv-software-src/riscv-isa-sim), the
RISC-V ISA simulator, with a patch stack for the uarchlabs performance model.
Upstream's own documentation is in [README.md](README.md); this file covers
only what ua-spike adds. The binary is still called `spike`.

## Branches

| Branch | Contents |
| --- | --- |
| `main` | Upstream plus our patch stack. Rebased onto `vendor/upstream` about monthly, so it is force-pushed |
| `vendor/upstream` | Exact copy of upstream `master`, updated by hand at the start of each rebase |
| `vendor/condor-devel` | Frozen copy of Condor Computing's `patch-stack/spike-stf-devel`, the reference for the ported features |
| `patch-stack/ua-spike-<date>-upstream-<sha>` | The state of `main` after each rebase, kept so every past base stays reproducible |

`vendor/*` and `patch-stack/*` are protected by a ruleset; repository admins
can update them.

## Monthly rebase

```sh
# 1. Bring vendor/upstream up to upstream master (fast-forward only)
git fetch upstream
git push origin upstream/master:refs/heads/vendor/upstream

# 2. Rebase main onto it
git fetch origin
git checkout main
git rebase origin/vendor/upstream        # resolve conflicts, build, test
git push --force-with-lease origin main  # wait for ua-spike CI to pass

# 3. Keep a snapshot of this rebase
base=$(git rev-parse --short origin/vendor/upstream)
git push origin main:refs/heads/patch-stack/ua-spike-$(date +%F)-upstream-$base

# 4. Note the riscv-opcodes commit Spike's decoder was generated from
grep -o 'riscv-opcodes ([0-9a-f]*)' riscv/encoding.h
```

Then, in uarchlabs/aspenapi, move the riscv-opcodes pin to that commit:

```sh
git -C ext/riscv-opcodes fetch
git -C ext/riscv-opcodes checkout <short sha from step 4>
git -C ext/riscv-opcodes rev-parse HEAD   # full sha
# set riscv_opcodes_commit in isa/profiles/rva23s64.yaml to that full sha
PYTHONPATH=python python3 -m aspen_isa ids --assign
PYTHONPATH=python python3 -m aspen_isa validate
git add ext/riscv-opcodes isa
git commit -m "Move riscv-opcodes pin to <short sha> (ua-spike rebase)"
```

If upstream's `encoding.h` still names the same riscv-opcodes commit, step 4
needs no aspenapi change.

## What the stack adds

Planned, in order:

1. Instruction counters, BBV generation, ROI and warmup tracks, ported from
   Condor Computing's Spike-STF fork without STF.
2. Checkpoint save and restore, ported from the same fork, then vector
   registers, ELF symbols and the LR/SC reservation.
3. Performance-model support: a library-mode stepping API, a store buffer and
   a wrong-path undo log.

Ported features credit Condor Computing's Spike-STF fork in their commit
messages and in [THIRD_PARTY_LICENSES](THIRD_PARTY_LICENSES).

To keep rebases small, new code goes in new files and the hooks in upstream
files stay thin. Our files live under `ua/`, `.github/workflows/ua-*.yml`,
this README and `THIRD_PARTY_LICENSES`.

## CI

`ua-ci.yml` runs on every push and pull request to `main`:

- **Upstream regression:** upstream's `ci-tests/build-spike` and
  `ci-tests/test-spike`.
- **Commit logs match upstream:** every riscv-tests RV64 ISA test runs on
  ua-spike and on stock upstream at our base commit, with `--log-commits`.
  Exit codes and commit logs must be identical. When `main` has no engine
  changes yet, one build serves both sides.

To run the commit-log check locally (Ubuntu 24.04, packages from
`.github/workflows/apt-packages.txt`):

```sh
ua/ci/build-spike.sh . /tmp/build-ours /tmp/ours
ua/ci/build-riscv-tests.sh /tmp/rt
ua/ci/commitlog-diff.sh /tmp/ours/bin/spike <upstream spike> /tmp/rt/isa /tmp/logs
```

## License

Spike is BSD-3-Clause (see [LICENSE](LICENSE)). Our additions use the same
license, so any of them can be offered upstream.
