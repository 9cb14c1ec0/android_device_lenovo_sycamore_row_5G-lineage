// Android 13 libprocessgroup exported C-linkage SetTaskProfiles/SetProcessProfiles
// wrappers, which the stock MediaTek hwcomposer imports. Android 16 only keeps
// the C++ overloads; re-export the old names and forward to them.
#include <processgroup/processgroup.h>

#include <string>
#include <vector>

extern "C" bool LegacySetTaskProfiles(int tid, const std::vector<std::string>& profiles,
                                      bool use_fd_cache) __asm__("SetTaskProfiles");
extern "C" bool LegacySetProcessProfiles(uid_t uid, pid_t pid,
                                         const std::vector<std::string>& profiles)
        __asm__("SetProcessProfiles");

extern "C" bool LegacySetTaskProfiles(int tid, const std::vector<std::string>& profiles,
                                      bool use_fd_cache) {
    return SetTaskProfiles(tid, profiles, use_fd_cache);
}

extern "C" bool LegacySetProcessProfiles(uid_t uid, pid_t pid,
                                         const std::vector<std::string>& profiles) {
    return SetProcessProfiles(uid, pid, profiles);
}
