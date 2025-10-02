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
        return sqrt(x * x + y * y + z * z) / 3
    }
    
    func toString() -> String {
        return "(\(x), \(y), \(z))"
    }
}

struct DataBundle: Sendable {
    let hr: UInt
    let acc: Double
    let gyro: Double
    let timestamp: Date
}

struct StreamSetting: Sendable {
    var sampleRate: UInt32?
    var resolution: UInt32?
    var range: UInt32?
    var channels: UInt32?
}

protocol SensorDataSource: ObservableObject {
    var hr: UInt { get }
    var acc: XYZ { get }
    var gyro: XYZ { get }
    var ppg: PPGArray { get }
    var timestamp: Date { get }
    
    var accStreamSetting: StreamSetting { get }
    var gyroStreamSetting: StreamSetting { get }
    var ppgStreamSetting: StreamSetting { get }
    
    @ObservationIgnored var dataBundleSubject: any Publisher<DataBundle, Never> { get }
    @ObservationIgnored var ppgDataSubject: any Publisher<PPGArray, Never> { get }
    
    var sensor: any Sensor { get set }
    
    init(sensor: any Sensor)
}
