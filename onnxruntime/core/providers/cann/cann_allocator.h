// Copyright (c) Microsoft Corporation. All rights reserved.
// Copyright (c) Huawei. All rights reserved.
// Licensed under the MIT License.

#pragma once

#include "core/common/inlined_containers.h"
#include "core/framework/allocator.h"
#include <mutex>

namespace onnxruntime {

class CANNAllocator : public IAllocator {
 public:
  CANNAllocator(OrtDevice::DeviceId device_id, const char* name)
      : IAllocator(
            OrtMemoryInfo(name, OrtAllocatorType::OrtDeviceAllocator,
                          OrtDevice(OrtDevice::NPU, OrtDevice::MemType::DEFAULT, OrtDevice::VendorIds::HUAWEI,
                                    device_id),
                          OrtMemTypeDefault)) {}
  void* Alloc(size_t size) override;
  void Free(void* p) override;
};

class CANNPinnedAllocator : public IAllocator {
 public:
  CANNPinnedAllocator(OrtDevice::DeviceId device_id, const char* name)
      : IAllocator(
            OrtMemoryInfo(name, OrtAllocatorType::OrtDeviceAllocator,
                          OrtDevice(OrtDevice::NPU, OrtDevice::MemType::HOST_ACCESSIBLE, OrtDevice::VendorIds::HUAWEI,
                                    device_id),
                          OrtMemTypeCPUOutput)) {}

  void* Alloc(size_t size) override;
  void Free(void* p) override;
};

}  // namespace onnxruntime
