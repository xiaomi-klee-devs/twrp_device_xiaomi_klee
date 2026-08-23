/*
 * libc++ verbose-abort shim for recovery.
 *
 * Vendor HAL binaries (keymint/gatekeeper) reference
 * __libcpp_verbose_abort from the NDK libc++, which is absent in the APEX-less
 * recovery environment. This translation unit defines the symbol (matching
 * the mangled name) so linking succeeds; at runtime it logs and aborts.
 */

#include <android/log.h>
#include <stdarg.h>
#include <stdlib.h>

extern "C" __attribute__((noreturn, visibility("default")))
void KleeLibcppVerboseAbort(const char* format, ...)
    __asm__("_ZNSt3__122__libcpp_verbose_abortEPKcz");

void KleeLibcppVerboseAbort(const char* format, ...) {
    va_list args;
    va_start(args, format);
    __android_log_vprint(ANDROID_LOG_FATAL, "klee-libcxx-compat", format, args);
    va_end(args);
    abort();
}
