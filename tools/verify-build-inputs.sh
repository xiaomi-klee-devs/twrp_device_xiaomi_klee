#!/usr/bin/env bash
set -euo pipefail

DEVICE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
TOP_DIR="${1:-$(cd -- "${DEVICE_DIR}/../../.." && pwd -P)}"
failures=0

fail() {
    echo "ERROR: $*" >&2
    failures=$((failures + 1))
}

if [[ "${RODIN_ALLOW_UNPINNED_SOURCE:-0}" != "1" ]]; then
    if ! python3 "${DEVICE_DIR}/tools/verify-source-manifest.py" "${TOP_DIR}" \
            "${DEVICE_DIR}/manifests/orangefox-fox_14.1-pinned.xml"; then
        fail "OrangeFox source tree differs from the pinned manifest"
    fi
fi

for script in \
    "${DEVICE_DIR}/build-lowmem.sh" \
    "${DEVICE_DIR}/fox_callback.sh" \
    "${DEVICE_DIR}/tools/build-system-compatible-vendor-boot.sh" \
    "${DEVICE_DIR}/tools/collect-compat-report.sh" \
    "${DEVICE_DIR}/tools/verify-build-inputs.sh"; do
    if [[ -f "$script" ]]; then
        bash -n "$script" || fail "shell syntax check failed: $script"
    fi
done

if [[ -f "${DEVICE_DIR}/tools/verify-source-manifest.py" ]]; then
    python3 "${DEVICE_DIR}/tools/verify-source-manifest.py" --help >/dev/null || \
        fail "Python syntax check failed: tools/verify-source-manifest.py"
fi

if (( failures > 0 )); then
    echo "Preflight failed with ${failures} error(s)" >&2
    exit 1
fi

echo "klee build input verification passed"
echo "OrangeFox top: ${TOP_DIR}"
echo "Device tree:   ${DEVICE_DIR}"
