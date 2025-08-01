//
//  SensorInfo.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 22.04.25.
//

import PolarBleSdk

struct SensorInfo: Hashable, Identifiable {
    var id: String { deviceId }
    
    let deviceId: String
    let address: String
    let rssi: Int
    let name: String
    let isConnectable: Bool
}

extension SensorInfo {
    static func toSensorInfo(polarDevice: PolarDeviceInfo, mockSuffix: String? = nil) -> SensorInfo {
        return .init(deviceId: polarDevice.deviceId + (mockSuffix ?? ""),
                     address: polarDevice.address.uuidString,
                     rssi: polarDevice.rssi,
                     name: polarDevice.name + (mockSuffix ?? ""),
                     isConnectable: polarDevice.connectable)
    }
}

extension SensorInfo {    
    var isValid: Bool { !deviceId.isEmpty && !name.isEmpty }
}
