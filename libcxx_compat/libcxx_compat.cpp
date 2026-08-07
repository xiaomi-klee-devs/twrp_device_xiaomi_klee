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
