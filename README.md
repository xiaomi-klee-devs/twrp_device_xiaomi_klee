# OrangeFox Recovery Device Tree - POCO X8 Pro / Redmi Turbo 5

The POCO X8 Pro / REDMI Turbo 5 (codenamed _"klee"_) are upper mid-range smartphones from Xiaomi's sub-brand POCO / REDMI.
Both devices were announced in April 2026.

## Device specifications

Basic   | Spec Sheet
-------:|:-------------------------
CPU     | Octa-core (1x3.4 GHz Cortex-A725 & 3x3.2 GHz Cortex-A725 & 4x2.2 GHz Cortex-A725)
Chipset | Mediatek Dimensity 8500-Ultra (MT6899)
GPU     | Mali-G720 MC8
Memory  | 8/12 GB RAM
Shipped Android Version | 16
Storage | 256/512 GB (UFS 4.1)
Battery | Non-removable Si/C Li-Ion 6500 mAh
Display | 1268 x 2756 pixels, 6.59 inches (~460 ppi pixel density)
Camera  | 50MP wide camera, 8MP ultra wide-angle camera, 20MP front camera

## Tree layout

| Path | Purpose |
|------|---------|
| `AndroidProducts.mk`, `twrp_klee.mk` | Lunch target (`twrp_klee-eng`) |
| `omni_klee.mk` | Omni-style product alias with stock ROM fingerprint |
| `BoardConfig.mk` | Board: arch, boot header, partitions, recovery flags (grouped + commented) |
| `device.mk` | Product packages, A/B OTA config, props |
| `fox_klee.mk` | OrangeFox-only device flags |
| `vendorsetup.sh` | Env defaults sourced by `envsetup.sh` |
| `Android.bp` | All Soong module definitions (sources live under `src/`) |
| `src/` | First-party C/C++ sources, one folder per module |
| `src/libcxx_compat/` | libc++ verbose-abort shim for stock vendor HALs |
| `src/omapi_bridge/` | OMAPI <-> eSE service bridge for decryption flows |
| `src/create_pl_dev/` | Preloader raw-partition mapper + its init rc |
| `recovery/root/` | Ramdisk overlay (fstabs, init rc, HALs, modules, firmware) |
| `prebuilt/` | Stock DTB, DTBO, kernel placeholder, stock vendor ramdisk fragment |
| `sepolicy/` | Device SELinux policy (UFS bootctl) |
| `security/` | Signing certificate |
| `patches/` | Idempotent patches for the OrangeFox source tree (**applied by CI/tooling**) |
| `manifests/` | Pinned repo manifest of the exact synced sources |
| `tools/` | All helper scripts (build, patching, verification, diagnostics) |

## Tools

| Script | Purpose |
|--------|---------|
| `tools/compile.sh` | Build entry point (low-RAM profile by default); logs to `out/logs/` |
| `tools/apply-orangefox-patches.sh` | Applies `patches/*.patch` onto build/make, bootable/recovery, system/core |
| `tools/build-system-compatible-vendor-boot.sh` | Repacks the final system-compatible vendor_boot image |
| `tools/verify-build-inputs.sh` | Preflight: pinned-manifest check + script syntax checks |
| `tools/verify-source-manifest.py` | Compares the synced tree against the pinned manifest |
| `tools/patch-vendor-boot-dtb.py` | Strips USB offload from the stock vendor-boot DTB |
| `tools/collect-compat-report.sh` | Collects touch/compat diagnostics over adb/fastboot |
| `tools/prepare-recovery-root.sh` | Post-build ramdisk hook (prune, UPX-pack) referenced by BoardConfig |

## Building

Builds are done through **GitHub Actions** - no local source tree required.
The workflow (`.github/workflows/build.yml`) handles everything end-to-end:
syncing the pinned OrangeFox sources, applying patches, verifying inputs,
building, repacking and publishing the image.

### Runner requirements

The job runs on a `self-hosted` runner and hard-fails without enough capacity:

| Resource | Minimum |
|----------|---------|
| Free disk | ~95 GiB |
| RAM       | 14 GiB  |
| Swap      | 12 GiB (set up automatically by the workflow) |

### No self-hosted runner? Use a free GitHub-hosted one

Fork this repository, then in **your fork** edit
`.github/workflows/build.yml` and change:

```yaml
runs-on: self-hosted
```

to:

```yaml
runs-on: ubuntu-24.04
```

The public `ubuntu-24.04` hosted runner (4 vCPU / 16 GB RAM) satisfies the
capacity guards above - the workflow frees disk space and sets up swap
automatically. Run the workflow from your fork exactly as described below;
artifacts and prereleases land in the fork.

### How to build

1. Push your changes to the repo (the workflow checks out this device tree).
2. Open the **Actions** tab -> **Build and publish OrangeFox klee**.
3. Click **Run workflow**:
   - leave every step toggle on (`true`) for a full clean build;
   - enable **publish** to create a prerelease when the build succeeds;
   - individual steps can be toggled off to re-run from a known-good state.
4. Wait for the run to finish (~a few hours on low-memory runners).

### Getting the output

Every successful run uploads these artifacts:

| Artifact | Contents |
|----------|----------|
| `orangefox-klee-release-<run>-<attempt>` | `OrangeFox-R12.0-Unofficial-klee-system-compatible.img` + `.sha256` |
| `orangefox-klee-logs-<run>-<attempt>` | Full build log (`orangefox-build.log`) and `out/logs/` |

If **publish** was enabled and the run happened on `main`, a **prerelease**
(tagged `klee-ci-<run>-<attempt>-<sha>`) is created automatically with the
flashable image attached. Flash it to the active slot:

```sh
fastboot flash vendor_boot OrangeFox-R12.0-Unofficial-klee-system-compatible.img
```
