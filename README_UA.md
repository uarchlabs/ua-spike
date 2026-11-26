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
| `vendor/upstream` | Exact copy of upstream `master`, fast-forwarded nightly by `ua-sync-upstream.yml` |
| `vendor/condor-devel` | Frozen copy of Condor Computing's `patch-stack/spike-stf-devel`, the reference for the ported features |
| `patch-stack/ua-spike-<date>-upstream-<sha>` | The state of `main` at each rebase, kept so every past base stays reproducible |

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
