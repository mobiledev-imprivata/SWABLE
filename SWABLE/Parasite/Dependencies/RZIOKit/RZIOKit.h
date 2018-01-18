//
//  RZIOKit.h
//
//  Created by Rob Visentin on 3/18/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#ifndef __RZIOKit__
#define __RZIOKit__

#include <CoreFoundation/CoreFoundation.h>
#include <mach/mach.h>

typedef	kern_return_t RZIOReturn;
typedef mach_port_t rz_io_object_t;
typedef rz_io_object_t rz_io_registry_entry_t;
typedef rz_io_registry_entry_t rz_io_service_t;
typedef rz_io_object_t rz_io_iterator_t;
typedef rz_io_object_t rz_io_connect_t;
typedef rz_io_object_t rz_io_name_t;
typedef rz_io_object_t rz_io_service_t;

CF_EXPORT mach_port_t kRZIOMasterPortDefault;

CF_EXPORT boolean_t RZIOObjectIsEqualTo(rz_io_object_t object, rz_io_object_t anObject);

CF_EXPORT CFDictionaryRef RZIOServiceMatching(const char *name);
CF_EXPORT CFDictionaryRef RZIOServiceNameMatching(const char *name);
CF_EXPORT rz_io_service_t RZIOServiceGetMatchingService(mach_port_t masterPort, CFDictionaryRef matching);
CF_EXPORT RZIOReturn RZIOServiceGetMatchingServices(mach_port_t masterPort, CFDictionaryRef matching, rz_io_iterator_t *iteratorPtr);

CF_EXPORT boolean_t RZIOIteratorIsValid(rz_io_iterator_t iterator);
CF_EXPORT rz_io_object_t RZIOIteratorNext(rz_io_iterator_t iterator);

CF_EXPORT RZIOReturn RZIOServiceOpen(rz_io_service_t service, task_port_t owningTask, uint32_t type, rz_io_connect_t *connect);
CF_EXPORT RZIOReturn RZIOServiceClose(rz_io_connect_t connect);

CF_EXPORT RZIOReturn RZIORegistryEntryGetName(rz_io_registry_entry_t entry, char *name);

CF_EXPORT CFTypeRef RZIORegistryEntryCreateCFProperty(rz_io_registry_entry_t entry, CFStringRef key, CFAllocatorRef allocator, __unused uint32_t options);

CF_EXPORT RZIOReturn RZIOObjectRelease(rz_io_service_t object);

CF_EXPORT RZIOReturn RZIOPMCopyCPUPowerStatus(CFDictionaryRef *cpuPowerStatus);
CF_EXPORT RZIOReturn RZIOPMGetThermalWarningLevel(uint32_t *thermalLevel);

#endif
