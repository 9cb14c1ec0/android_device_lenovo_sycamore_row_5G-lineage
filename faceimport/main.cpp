/*
 * The ArcSoft face HAL registers a callback with Lenovo's faceimport service
 * at startup and refuses sessions until it is told that importing face
 * templates from a previous system has finished. Stock sends that from a
 * Lenovo app through IFaceImport::finishImport; LineageOS has no such caller.
 *
 * Started when the face HAL comes up; the delay lets the HAL register its
 * callback first. finishImport must only be called once per HAL start.
 */
#define LOG_TAG "face_import_finish"

#include <android/binder_ibinder.h>
#include <android/binder_manager.h>
#include <android/binder_parcel.h>
#include <log/log.h>
#include <unistd.h>

namespace {

constexpr char kDescriptor[] = "vendor.lenovo.hardware.faceimport.IFaceImport";
constexpr char kInstance[] = "vendor.lenovo.hardware.faceimport.IFaceImport/default";
// int finishImport() is method 2 (vendor.lenovo.hardware.faceimport-V1-ndk.so).
constexpr transaction_code_t kFinishImport = FIRST_CALL_TRANSACTION + 1;
constexpr unsigned kCallbackDelaySeconds = 3;

void* onCreate(void*) { return nullptr; }
void onDestroy(void*) {}
binder_status_t onTransact(AIBinder*, transaction_code_t, const AParcel*, AParcel*) {
    return STATUS_UNKNOWN_TRANSACTION;
}

}  // namespace

int main() {
    AIBinder* binder = nullptr;
    for (int i = 0; i < 60 && binder == nullptr; i++) {
        binder = AServiceManager_checkService(kInstance);
        if (binder == nullptr) sleep(1);
    }
    if (binder == nullptr) {
        ALOGE("%s not found", kInstance);
        return 1;
    }
    AIBinder_Class* clazz = AIBinder_Class_define(kDescriptor, onCreate, onDestroy, onTransact);
    AIBinder_associateClass(binder, clazz);

    sleep(kCallbackDelaySeconds);

    AParcel* in = nullptr;
    AParcel* out = nullptr;
    binder_status_t status = AIBinder_prepareTransaction(binder, &in);
    if (status == STATUS_OK) status = AIBinder_transact(binder, kFinishImport, &in, &out, 0);
    AParcel_delete(in);
    AParcel_delete(out);
    AIBinder_decStrong(binder);
    if (status != STATUS_OK) {
        ALOGE("finishImport failed: %d", status);
        return 1;
    }
    ALOGI("finished face template import");
    return 0;
}
