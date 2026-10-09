/*
 * The modem's data policy (D2AM) refuses every PDN except IMS with
 * VZW_DATA_NOT_ALLOWED (0x141678) until it has been told that mobile data is
 * on. Stock sends that from MediaTek's telephony framework through
 * IMtkRadioExData::syncDataSettingsToMd; LineageOS has no such caller.
 *
 * Android still decides whether data, and roaming data, is actually used, so
 * the modem is told both are allowed. The default data SIM is the first slot
 * with a card application.
 *
 * Usage: mtk_data_settings <UICC type of each slot, "none" if empty>...
 * (vendor.gsm.ril.uicctype[.N]; gsm.sim.state is not readable from vendor)
 */
#define LOG_TAG "mtk_data_settings"

#include <android/binder_ibinder.h>
#include <android/binder_manager.h>
#include <android/binder_parcel.h>
#include <log/log.h>
#include <unistd.h>

#include <string>
#include <vector>

namespace {

constexpr char kDescriptor[] = "vendor.mediatek.hardware.mtkradioex.data.IMtkRadioExData";
// oneway syncDataSettingsToMd(int serial, int[] settings, int) is method 8
// (vendor.mediatek.hardware.mtkradioex.data-V1-ndk.so).
constexpr transaction_code_t kSyncDataSettingsToMd = FIRST_CALL_TRANSACTION + 7;
constexpr int kUnchanged = -2;
constexpr int kSlots = 2;

void* onCreate(void*) { return nullptr; }
void onDestroy(void*) {}
binder_status_t onTransact(AIBinder*, transaction_code_t, const AParcel*, AParcel*) {
    return STATUS_UNKNOWN_TRANSACTION;
}

bool sync(AIBinder_Class* clazz, int slot, const std::vector<int32_t>& settings) {
    std::string name = std::string(kDescriptor) + "/slot" + std::to_string(slot + 1);
    AIBinder* binder = nullptr;
    for (int i = 0; i < 60 && binder == nullptr; i++) {
        binder = AServiceManager_checkService(name.c_str());
        if (binder == nullptr) sleep(1);
    }
    if (binder == nullptr) {
        ALOGE("%s not found", name.c_str());
        return false;
    }
    AIBinder_associateClass(binder, clazz);

    AParcel* in = nullptr;
    AParcel* out = nullptr;
    binder_status_t status = AIBinder_prepareTransaction(binder, &in);
    if (status == STATUS_OK) status = AParcel_writeInt32(in, 0);
    if (status == STATUS_OK)
        status = AParcel_writeInt32Array(in, settings.data(), settings.size());
    if (status == STATUS_OK) status = AParcel_writeInt32(in, 0);
    if (status == STATUS_OK)
        status = AIBinder_transact(binder, kSyncDataSettingsToMd, &in, &out, FLAG_ONEWAY);
    AParcel_delete(in);
    AParcel_delete(out);
    AIBinder_decStrong(binder);
    if (status != STATUS_OK) ALOGE("slot%d: sync failed: %d", slot + 1, status);
    return status == STATUS_OK;
}

}  // namespace

int main(int argc, char** argv) {
    int dataSlot = kUnchanged;
    for (int slot = 0; slot + 1 < argc && slot < kSlots; slot++) {
        std::string type = argv[slot + 1];
        if (!type.empty() && type != "none") {
            dataSlot = slot;
            break;
        }
    }

    AIBinder_Class* clazz = AIBinder_Class_define(kDescriptor, onCreate, onDestroy, onTransact);
    // {mobile data, roaming, default data slot, domestic roaming, international roaming}
    std::vector<int32_t> settings = {1, 1, dataSlot, kUnchanged, kUnchanged};
    bool ok = true;
    for (int slot = 0; slot < kSlots; slot++) ok &= sync(clazz, slot, settings);
    ALOGI("synced data settings, default data slot %d", dataSlot);
    return ok ? 0 : 1;
}
