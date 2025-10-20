//
//  Sensor.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 24.04.25.
//

import Foundation
import Combine

enum SensorState: Equatable, Sendable {
    case disconnected
    case connecting(SensorInfo)
    case connected(SensorInfo)
    case streaming(String)
}

enum SensorError: Error, Sendable {
    case connectionFailed
}

protocol ConnectionDelegate: AnyObject, Sendable {
    func onConnected(sensor: SensorInfo)
    func onDisconnected()
}

enum ConnectionState: Equatable, Sendable {
    case connected(sensor: SensorInfo)
    case disconnected
}

protocol SensorStateObservable: Actor {
    var apiProvider: BleApiProvider { get }

    var state: any Publisher<SensorState, Never> { get }
    var batteryLevel: any Publisher<UInt, Never> { get }
    var isBlePowerOn: any Publisher<Bool, Never> { get }
    var rssi: any Publisher<Int, Never> { get }
    
    func setStreamingState(deviceId: String) async
}

protocol SensorConnectable: Actor {
    var connectionState: any Publisher<ConnectionState, Never> { get }
    
    func connect(to sensorId: String) async throws 
    func autoConnect() async throws
    func disconnect(removeFromStorage: Bool) async throws
    
    func setLogOn(_ state: Bool) async
}

typealias Sensor = SensorStateObservable & SensorConnectable
