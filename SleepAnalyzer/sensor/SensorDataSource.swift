//
//  SensorDataSource.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 15.04.25.
//

import Foundation

typealias PPGData = [(timeStamp: UInt64, sample: Int32)]

struct XYZ {
    let x: Double
    let y: Double
    let z: Double
    
    func rmse() -> Double {
        return sqrt(x * x + y * y + z * z) / 3
    }
}

struct StreamSetting: Sendable {
    var sampleRate: UInt32?
    var resolution: UInt32?
    var range: UInt32?
    var channels: UInt32? 
}

struct DataBundle: Sendable {
    let hr: UInt
    let acc: Double
    let gyro: Double
    let timestamp: Date
}

//
// use @Environment(\.sensorDataSource) var data
//
protocol SensorDataSource: ObservableObject {
    
    var hr: UInt { get }
    var acc: XYZ { get }
    var gyro: XYZ { get }
    var ppg: PPGData { get }
    var timestamp: Date { get }
    
    var accStreamSetting: StreamSetting { get }
    var gyroStreamSetting: StreamSetting { get }
    var ppgStreamSetting: StreamSetting { get }
    
    @ObservationIgnored var dataBundleCombinedLatest: ObservableEvent<DataBundle> { get }
    @ObservationIgnored var ppgObservable: ObservableEvent<PPGData> { get }
    
    var sensor: any Sensor { get set }
    
    init(sensor: any Sensor)
}
