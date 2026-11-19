import Foundation

#if os(iOS)
    import UIKit
#elseif os(macOS)
    import IOKit
#endif

/// The ID the device is known by to the server.
@MainActor
enum DeviceIdentifier {
    #if os(iOS)
        static var vendorID: String? { UIDevice.current.identifierForVendor?.uuidString }
    #elseif os(macOS)
        static var machineID: String? {
            let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
            defer { IOObjectRelease(service) }
            return IORegistryEntryCreateCFProperty(service, "IOPlatformUUID" as CFString, kCFAllocatorDefault, 0)?
                .takeRetainedValue() as? String
        }
    #endif
}
