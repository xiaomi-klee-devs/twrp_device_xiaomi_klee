#!/sbin/sh
# Loads the Novatek NT38771 touch driver and the Xiaomi touch framework.
#
# All three modules ship inside the recovery ramdisk (vendor_boot) and must be
# loaded in dependency order: miev -> xiaomi_touch_klee -> nt38771_touch_klee.

set +e

mod_dir="/lib/modules"

load_module() {
    module="$1"
    name="${module%.ko}"
    grep -q "^${name} " /proc/modules && return 0
    insmod "${mod_dir}/${module}" 2>/dev/null
}

load_module miev.ko
load_module xiaomi_touch_klee.ko
load_module nt38771_touch_klee.ko
