# ============================================================================
# vendorsetup.sh - sourced automatically by `source build/envsetup.sh`
# Exports device defaults before any lunch target is selected.
#
# NOTE: the low-memory build knobs (jobs/Go GC/java heap) live here AND in
# tools/compile.sh; that script re-exports them for standalone builds.
# ============================================================================

# --- OrangeFox build-system switches ----------------------------------------
export ALLOW_MISSING_DEPENDENCIES=true      # recovery-only tree, tolerate gaps
export FOX_BUILD_DEVICE=rodin                # device codename for Fox scripts
export FOX_AB_DEVICE=1                      # A/B (seamless update) device
export FOX_VIRTUAL_AB_DEVICE=1              # virtual A/B with snapshots

# Use full GNU userland binaries instead of toybox applets in the ramdisk
export FOX_USE_BASH_SHELL=1
export FOX_ASH_IS_BASH=1
export FOX_USE_GREP_BINARY=1
export FOX_USE_SED_BINARY=1
export FOX_USE_TAR_BINARY=1
export FOX_USE_XZ_UTILS=1
export FOX_USE_ZIP_BINARY=1
export FOX_USE_LZ4_BINARY=1

# Never compile a kernel; always reuse the prebuilt one from prebuilt/
export OF_FORCE_PREBUILT_KERNEL=1
export OF_USE_LZ4_COMPRESSION=1

# --- Low-memory build profile (CI runners / small hosts) --------------------
# Single-threaded ninja + capped Go/JVM heaps keep peak RSS under ~8 GiB.
export OF_LOW_MEMORY_BUILD="${OF_LOW_MEMORY_BUILD:-1}"
if [ "${OF_LOW_MEMORY_BUILD}" = "1" ]; then
    export OF_BUILD_JOBS="${OF_BUILD_JOBS:-1}"
    export NINJA_ARGS="${NINJA_ARGS:--j${OF_BUILD_JOBS} -l${OF_BUILD_JOBS}}"
    export SOONG_UI_NINJA_ARGS="${SOONG_UI_NINJA_ARGS:--j${OF_BUILD_JOBS} -l${OF_BUILD_JOBS}}"
    export NINJA_HIGHMEM_NUM_JOBS="${NINJA_HIGHMEM_NUM_JOBS:-1}"
    export GOMAXPROCS="${GOMAXPROCS:-1}"
    export GOGC="${GOGC:-20}"
    export GOMEMLIMIT="${GOMEMLIMIT:-6GiB}"
    export _JAVA_OPTIONS="${_JAVA_OPTIONS:--Xmx1g}"
fi
