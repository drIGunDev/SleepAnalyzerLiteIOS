import Foundation

open class BlePolarDeviceCapabilitiesUtility {
    public enum FileSystemType {
        case unknownFileSystem
        case h10FileSystem
        case polarFileSystemV2
    }

    private static let fileName = "polar_device_capabilities.json"
    private static var initialized = false
    private static var configData: Data?
    private static var capabilities: [String: DeviceCapabilities] = [:]
    private static var defaults: DeviceCapabilities?

    /// Representation of device capabilities loaded from JSON
    private struct DeviceCapabilities: Codable {
        let fileSystemType: String?
        let recordingSupported: Bool?
        let firmwareUpdateSupported: Bool?
        let activityDataSupported: Bool?
        let isDeviceSensor: Bool?
    }

    private struct DeviceCapabilitiesConfig: Codable {
        let defaults: DeviceCapabilities
        let devices: [String: DeviceCapabilities]
    }

    /// Initializes the device capabilities configuration.
    /// Loads from Documents folder first. If missing, copies default from bundle.
    public static func initialize() {
        guard !initialized else { return }

        do {
            let fileManager = FileManager.default
            let documentsURL = try fileManager.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let polarConfigURL = documentsURL.appendingPathComponent(fileName)

            if !fileManager.fileExists(atPath: polarConfigURL.path) {
                guard let bundleURL = Bundle.main.url(
                    forResource: "polar_device_capabilities",
                    withExtension: "json"
                ) else {
                    print("BlePolarDeviceCapabilitiesUtility: Failed to initialize device capabilities: Default config not found in bundle")
                    return
                }
                try fileManager.copyItem(at: bundleURL, to: polarConfigURL)
                print("BlePolarDeviceCapabilitiesUtility: Default config copied to Documents folder")
            } else {
                print("BlePolarDeviceCapabilitiesUtility: Using existing capabilities from Documents folder")
            }

            configData = try Data(contentsOf: polarConfigURL)

            if let jsonString = String(data: configData!, encoding: .utf8) {
                print("BlePolarDeviceCapabilitiesUtility: Device capabilities initialized successfully:\n\(jsonString)")
            } else {
                print("BlePolarDeviceCapabilitiesUtility: Device capabilities initialized, but JSON decoding failed")
            }

            // Decode JSON into dictionary keyed by device type
            let decoder = JSONDecoder()
            let config = try decoder.decode(DeviceCapabilitiesConfig.self, from: configData!)
            defaults = config.defaults
            capabilities = config.devices

            initialized = true
        } catch {
            print("BlePolarDeviceCapabilitiesUtility: Failed to initialize device capabilities: \(error)")
        }
    }

    /// Get type of filesystem the device supports
    /// - Parameter deviceType:  device type
    /// - Returns: type of the file system supported or unknown file system type
    public static func fileSystemType(_ deviceType: String) -> FileSystemType {
        if !initialized { initialize() }

        let fsType = (capabilities[deviceType.lowercased()] ?? defaults)?.fileSystemType?.uppercased()
        switch fsType {
        case "H10_FILE_SYSTEM":
            return .h10FileSystem
        case "POLAR_FILE_SYSTEM_V2":
            return .polarFileSystemV2
        default:
            return .unknownFileSystem
        }
    }

    /// Check if device is supporting recording start and stop over BLE
    /// - Parameter deviceType: device type
    /// - Returns: true if device supports recoding
    public static func isRecordingSupported(_ deviceType: String) -> Bool {
        if !initialized { initialize() }
        return capabilities[deviceType.lowercased()]?.recordingSupported ?? defaults?.recordingSupported ?? false
    }
    
    /// Check if device is supporting firmware update
    /// - Parameter deviceType: device type
    /// - Returns: true if device firmware update
    public static func isFirmwareUpdateSupported(_ deviceType: String) -> Bool {
        if !initialized { initialize() }
        return capabilities[deviceType.lowercased()]?.firmwareUpdateSupported ?? defaults?.firmwareUpdateSupported ?? false
    }

    /// Check if device is supporting activity data
    /// - Parameter deviceType: device type
    /// - Returns: true if device supports activity data
    public static func isActivityDataSupported(_ deviceType: String) -> Bool {
        if !initialized { initialize() }
        return capabilities[deviceType.lowercased()]?.activityDataSupported ?? defaults?.activityDataSupported ?? false
    }

    public static func isDeviceSensor(_ deviceType: String) -> Bool {
        if !initialized { initialize() }
        return capabilities[deviceType.lowercased()]?.isDeviceSensor ?? defaults?.isDeviceSensor ?? false
    }
}
