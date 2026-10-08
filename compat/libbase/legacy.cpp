// Legacy libbase entry points used by the stock Lenovo vendor binaries.
// Android 16 changed these signatures; forward to the current implementation.
#include <android-base/file.h>
#include <android-base/strings.h>

#include <string>
#include <string_view>

namespace android::base {
bool WriteStringToFd(const std::string& text, borrowed_fd fd) {
    return WriteStringToFd(std::string_view(text), fd);
}

std::string Basename(const std::string& path) {
    return Basename(std::string_view(path));
}

std::string Trim(const std::string& text) {
    return Trim(std::string_view(text));
}
}  // namespace android::base
