//
//  SensorDataSource.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 15.04.25.
//

import Foundation
import Combine

typealias PPGPoint = (timeStamp: UInt64, sample: Int32)
typealias PPGArray = [PPGPoint]

struct XYZ {
    let x: Double
    let y: Double
    let z: Double
    
    func rmse() -> Double {
        sqrt(x * x + y * y + z * z) / 3
    }
    
    func toString() -> String {
        "(\(x), \(y), \(z))"
    }
    
    static var `default`: XYZ {
        XYZ(x: 0, y: 0, z: 0)
    }
}

struct DataBundle: Sendable {
    let hr: UInt
    let acc: Double
    let gyro: Double
    let timestamp: Date
    
    static var `default`: DataBundle {
        DataBundle(hr: 0, acc: 0, gyro: 0, timestamp: .now)
    }
}

struct StreamSetting: Sendable {
    var sampleRate: UInt32?
    var resolution: UInt32?
    var range: UInt32?
    var channels: UInt32?
}

protocol SensorDataSource: Actor {
    var hr: any Publisher<UInt, Never> { get }
    var acc: any Publisher<XYZ, Never> { get }
    var gyro: any Publisher<XYZ, Never> { get }
    var ppg: any Publisher<PPGArray, Never> { get }
    var dataBundle: any Publisher<DataBundle, Never> { get }
    
    var accStreamSetting: StreamSetting? { get }
    var gyroStreamSetting: StreamSetting? { get }
    var ppgStreamSetting: StreamSetting? { get }
    
    @MainActor var sensor: any Sensor { get set }
    
    init(sensor: any Sensor)
}
