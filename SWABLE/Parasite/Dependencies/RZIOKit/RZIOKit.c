//
//  RZIOKit.c
//
//  Created by Rob Visentin on 3/18/15.
//  Copyright (c) 2015 Raizlabs. All rights reserved.
//

#include <dlfcn.h>

#include "RZIOKit.h"

mach_port_t kRZIOMasterPortDefault;

RZIOReturn (*_RZIOObjectGetClass)(rz_io_object_t object, char *name);
boolean_t (*_RZIOObjectIsEqualTo)(rz_io_object_t object, rz_io_object_t anObject);

CFDictionaryRef (*_RZIOServiceMatching)(const char *name);
CFDictionaryRef (*_RZIOServiceNameMatching)(const char *name);
rz_io_service_t (*_RZIOServiceGetMatchingService)(mach_port_t masterPort, CFDictionaryRef matching);
RZIOReturn (*_RZIOServiceGetMatchingServices)(mach_port_t masterPort, CFDictionaryRef matching, rz_io_iterator_t *iteratorPtr);

boolean_t (*_RZIOIteratorIsValid)(rz_io_iterator_t iterator);
rz_io_object_t (*_RZIOIteratorNext)(rz_io_iterator_t iterator);

RZIOReturn (*_RZIOServiceOpen)(rz_io_service_t service, task_port_t owningTask, uint32_t type, rz_io_connect_t *connect);
RZIOReturn (*_RZIOServiceClose)(rz_io_connect_t connect);

RZIOReturn (*_RZIORegistryEntryGetName)(rz_io_registry_entry_t entry, char *name);


CFTypeRef (*_RZIORegistryEntryCreateCFProperty)(rz_io_registry_entry_t entry, CFStringRef key, CFAllocatorRef allocator, __unused uint32_t options);

RZIOReturn (*_RZIOObjectRelease)(rz_io_service_t object);

RZIOReturn (*_RZIOPMCopyCPUPowerStatus)(CFDictionaryRef *cpuPowerStatus);
RZIOReturn (*_RZIOPMGetThermalWarningLevel)(uint32_t *thermalLevel);

const char *kRZIOKitFrameworkPath = "/System/Library/PrivateFrameworks/IOKit.framework/IOKit";

void ut_prepareIOKitSymbols(void) __attribute__((constructor));
void ut_prepareIOKitSymbols(void)
{
    void *iokit_handle = dlopen(kRZIOKitFrameworkPath, RTLD_LAZY);

    void *masterPort = dlsym(iokit_handle, "kIOMasterPortDefault");
    kRZIOMasterPortDefault = masterPort != NULL ? *(mach_port_t *)(masterPort) : 0;
    _RZIOObjectGetClass = dlsym(iokit_handle, "IOObjectGetClass");
    _RZIOObjectIsEqualTo = dlsym(iokit_handle, "IOObjectIsEqualTo");
    _RZIOServiceMatching = dlsym(iokit_handle, "IOServiceMatching");
    _RZIOServiceNameMatching = dlsym(iokit_handle, "IOServiceNameMatching");
    _RZIOServiceGetMatchingService = dlsym(iokit_handle, "IOServiceGetMatchingService");
    _RZIOServiceGetMatchingServices = dlsym(iokit_handle, "IOServiceGetMatchingServices");
    _RZIOIteratorIsValid = dlsym(iokit_handle, "IOIteratorIsValid");
    _RZIOIteratorNext = dlsym(iokit_handle, "IOIteratorNext");
    _RZIOServiceOpen = dlsym(iokit_handle, "IOServiceOpen");
    _RZIOServiceClose = dlsym(iokit_handle, "IOServiceClose");
    _RZIORegistryEntryGetName = dlsym(iokit_handle, "IORegistryEntryGetName");
    _RZIORegistryEntryCreateCFProperty = dlsym(iokit_handle, "IORegistryEntryCreateCFProperty");
    _RZIOObjectRelease = dlsym(iokit_handle, "IOObjectRelease");
    _RZIOPMCopyCPUPowerStatus = dlsym(iokit_handle, "IOPMCopyCPUPowerStatus");
    _RZIOPMGetThermalWarningLevel = dlsym(iokit_handle, "IOPMGetThermalWarningLevel");
}

#pragma mark - public methods

RZIOReturn RZIOObjectGetClass(rz_io_object_t object, char *name)
{
    return _RZIOObjectGetClass(object, name);
}

boolean_t RZIOObjectIsEqualTo(rz_io_object_t object, rz_io_object_t anObject)
{
    return _RZIOObjectIsEqualTo(object, anObject);
}

CFDictionaryRef RZIOServiceMatching(const char *name)
{
    return _RZIOServiceMatching(name);
}

CFDictionaryRef RZIOServiceNameMatching(const char *name)
{
    return _RZIOServiceNameMatching(name);
}

rz_io_service_t RZIOServiceGetMatchingService(mach_port_t masterPort, CFDictionaryRef matching)
{
    return _RZIOServiceGetMatchingService(masterPort, matching);
}

RZIOReturn RZIOServiceGetMatchingServices(mach_port_t masterPort, CFDictionaryRef matching, rz_io_iterator_t *iteratorPtr)
{
    return _RZIOServiceGetMatchingServices(masterPort, matching, iteratorPtr);
}

boolean_t RZIOIteratorIsValid(rz_io_iterator_t iterator)
{
    return _RZIOIteratorIsValid(iterator);
}

rz_io_object_t RZIOIteratorNext(rz_io_iterator_t iterator)
{
    return _RZIOIteratorNext(iterator);
}

RZIOReturn RZIOServiceOpen(rz_io_service_t service, task_port_t owningTask, uint32_t type, rz_io_connect_t *connect)
{
    return _RZIOServiceOpen(service, owningTask, type, connect);
}

RZIOReturn RZIOServiceClose(rz_io_connect_t connect)
{
    return _RZIOServiceClose(connect);
}

RZIOReturn RZIORegistryEntryGetName (rz_io_registry_entry_t entry, char *name)
{
    return _RZIORegistryEntryGetName(entry, name);
}


CFTypeRef RZIORegistryEntryCreateCFProperty ( rz_io_registry_entry_t entry, CFStringRef key, CFAllocatorRef allocator, __unused uint32_t options)
{
    return _RZIORegistryEntryCreateCFProperty(entry, key, allocator, options);
}

RZIOReturn RZIOObjectRelease(rz_io_service_t object)
{
    return _RZIOObjectRelease(object);
}

RZIOReturn RZIOPMCopyCPUPowerStatus(CFDictionaryRef *cpuPowerStatus)
{
    return _RZIOPMCopyCPUPowerStatus(cpuPowerStatus);
}

RZIOReturn RZIOPMGetThermalWarningLevel(uint32_t *thermalLevel)
{
    return _RZIOPMGetThermalWarningLevel(thermalLevel);
}

void RZIOPrintServices() {
    CFDictionaryRef matcher = RZIOServiceMatching("IOService");

    rz_io_iterator_t iterator = 0;
    RZIOServiceGetMatchingServices(kRZIOMasterPortDefault, matcher, &iterator);

    rz_io_object_t service = RZIOIteratorNext(iterator);

    while ( service != 0 ) {
        char name[256];
        RZIORegistryEntryGetName(service, name);

        printf("%s\n", name);

        RZIOObjectRelease(service);
        service = RZIOIteratorNext(iterator);
    }

    RZIOObjectRelease(iterator);
}
