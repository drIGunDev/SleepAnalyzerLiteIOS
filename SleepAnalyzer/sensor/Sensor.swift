//
//  Sensor.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 24.04.25.
//

import Foundation

enum SensorState: Equatable {
    case disconnected
    case connecting(SensorInfo)
    case connected(SensorInfo)
    case streaming(String)
}

enum SensorError: Error {
    case connectionFailed
}

protocol ConnectionDelegate {
    func onConnected(sensor: SensorInfo)
    func onDisconnected()
}

protocol SensorStateObservable: ObservableObject, AnyObject {
    var state: SensorState { get set }
    
    var batteryLevel: UInt { get }
    var isBlePowerOn: Bool { get }
    var rssi: Int { get }
    
    func setStreamingState(deviceId: String)
}

protocol SensorConnectable: ObservableObject, AnyObject {
    var connectedSensor: SensorInfo? { get }
    var isConnected: Bool { get }
    
    var connectionDelegate: ConnectionDelegate? { get set }
    @ObservationIgnored var apiProvider: PolarBleApiProvider { get set }
    
    init(apiProvider: PolarBleApiProvider)
    
    func connect(to sensorId: String) throws
    func autoConnect() throws
    func disconnect(removeFromStorage: Bool) throws
    
    func setLogOn(_ state: Bool)
}

typealias Sensor = SensorStateObservable & SensorConnectable
