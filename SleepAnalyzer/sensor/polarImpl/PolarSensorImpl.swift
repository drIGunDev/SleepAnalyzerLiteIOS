//
//  PolarSensorImpl.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 24.04.25.
//

import Foundation
import PolarBleSdk
import CoreBluetooth
import RxSwift
import SwiftUI
import Combine
import SwiftInjectLite

// MARK: - API

// MARK: - SensorStateObservable

@Observable final class PolarSensorImpl: SensorStateObservable {
    
    @ObservationIgnored internal var apiProvider: PolarBleApiProvider
    
    var connectedSensor: SensorInfo?
    
    var state: SensorState = .disconnected
    var batteryLevel: UInt = 0
    var isBlePowerOn = false
    var rssi: Int = -200
    
    var isConnected: Bool { connectedSensor != nil }
    
    @ObservationIgnored var connectionDelegate: ConnectionDelegate?
    
    @ObservationIgnored private var hrBroadcastDisposable: Disposable?
    @ObservationIgnored private var logOn = false
    
    init(apiProvider: PolarBleApiProvider) {
        self.apiProvider = apiProvider
        self.apiProvider.api.logger = self
        self.apiProvider.api.observer = self
        self.apiProvider.api.powerStateObserver = self
        self.apiProvider.api.deviceInfoObserver = self
    }
    
    deinit {
        self.hrBroadcastDisposable?.dispose()
        self.apiProvider.api.logger = nil
        self.apiProvider.api.observer = nil
        self.apiProvider.api.powerStateObserver = nil
        self.apiProvider.api.deviceInfoObserver = nil
    }
}

// MARK: - SensorConnectable

extension PolarSensorImpl: SensorConnectable {
    
    func connect(to sensorId: String) throws {
        try self.apiProvider.api.connectToDevice(sensorId)
    }
    
    func autoConnect() throws {
        if let savedSensorId = AppSettings.shared.sensorId, !savedSensorId.isEmpty {
            try connect(to: savedSensorId)
        }
        else {
            throw SensorError.connectionFailed
        }
    }
    
    func disconnect(removeFromStorage: Bool = true) throws {
        if let connectedSensorId = self.connectedSensor?.deviceId {
            try apiProvider.api.disconnectFromDevice(connectedSensorId)
            if removeFromStorage {
                updateSavedSensorId(nil)
            }
        }
    }
    
    func setStreamingState(deviceId: String) {
        self.state = .streaming(deviceId)
    }
    
    func setLogOn(_ state: Bool) {
        self.logOn = state
    }
    
    private func updateSavedSensorId(_ sensorId: String?) {
        var settings = AppSettings.shared
        settings.sensorId = sensorId
    }
    
    private func setDefaultValues() {
        self.batteryLevel = 0
        self.rssi = 0
    }
}

extension PolarSensorImpl {
    func startHRBroadcast() {
        if let sensor = self.connectedSensor {
            hrBroadcastDisposable?.dispose()
            hrBroadcastDisposable = apiProvider.api.startListenForPolarHrBroadcasts([sensor.deviceId])
                .observe(on: MainScheduler.instance)
                .subscribe{ [weak self] e in
                    switch e {
                    case .completed:
                        Logger.d("Broadcast listener completed")
                    case .error(let err):
                        Logger.e("Broadcast listener failed. Reason: \(err)")
                    case .next(let broadcast):
                        self?.rssi = Int(broadcast.deviceInfo.rssi)
                    }
                }
        }
        else {
            Logger.w("No connected sensor")
        }
    }
    
    func stopHRBroadcast() {
        hrBroadcastDisposable?.dispose()
    }
}

// MARK: - PolarBleApiObserver

extension PolarSensorImpl: PolarBleApiObserver {
    func deviceConnecting(_ identifier: PolarBleSdk.PolarDeviceInfo) {
        let sensor = SensorInfo.toSensorInfo(polarDevice: identifier)
        self.state = .connecting(sensor)
        Logger.d("connecting: \(identifier)")
    }
    
    func deviceConnected(_ identifier: PolarBleSdk.PolarDeviceInfo) {
        let sensor = SensorInfo.toSensorInfo(polarDevice: identifier)
        self.state = .connected(sensor)
        self.connectedSensor = sensor
        updateSavedSensorId(sensor.deviceId)
        startHRBroadcast()
        self.connectionDelegate?.onConnected(sensor: sensor)
        Logger.d( "connected: \(identifier)")
    }
    
    func deviceDisconnected(_ identifier: PolarBleSdk.PolarDeviceInfo, pairingError: Bool) {
        self.state = .disconnected
        stopHRBroadcast()
        self.connectionDelegate?.onDisconnected()
        setDefaultValues()
        Logger.d( "disconnected: \(identifier)")
    }
}

// MARK: - PolarBleApiDeviceInfoObserver

extension PolarSensorImpl: PolarBleApiDeviceInfoObserver {
    func batteryLevelReceived(_ identifier: String, batteryLevel: UInt) {
        self.batteryLevel = batteryLevel
        Logger.d( "batteryLevel: \(batteryLevel)")
    }
    
    func batteryChargingStatusReceived(_ identifier: String, chargingStatus: PolarBleSdk.BleBasClient.ChargeState) {}
    func disInformationReceived(_ identifier: String, uuid: CBUUID, value: String) {}
    func disInformationReceivedWithKeysAsStrings(_ identifier: String, key: String, value: String) {}
}

// MARK: - PolarBleApiPowerStateObserver

extension PolarSensorImpl: PolarBleApiPowerStateObserver {
    func blePowerOn() {
        isBlePowerOn = true
        Logger.d("BLE power on")
    }
    
    func blePowerOff() {
        isBlePowerOn = false
        Logger.d( "BLE power off")
    }
}

// MARK: - PolarBleApiLogger

extension PolarSensorImpl: PolarBleApiLogger {
    func message(_ str: String) {
        guard logOn else { return }
        Logger.d(">>>> \(str)")
    }
}

// MARK: - DI

extension InjectionRegistry {
    var sensor: any Sensor {
        get {
            let apiProvider = Self.inject(\.apiProvider)
            return Self.instantiate(.singleton) { PolarSensorImpl(apiProvider: apiProvider) }
        }
    }
}
