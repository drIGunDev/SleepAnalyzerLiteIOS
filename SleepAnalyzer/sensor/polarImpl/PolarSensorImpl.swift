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
import Combine
import SwiftInjectLite

// MARK: - SensorStateObservable

private actor PolarSensorImpl: SensorStateObservable {

    private let stateSubject = CurrentValueSubject<SensorState, Never>(.disconnected)
    var state: any Publisher<SensorState, Never> { stateSubject.eraseToAnyPublisher() }

    private let batteryLevelSubject = CurrentValueSubject<UInt, Never>(0)
    var batteryLevel: any Publisher<UInt, Never> { batteryLevelSubject.eraseToAnyPublisher() }

    private let isBlePowerOnSubject = CurrentValueSubject<Bool, Never>(false)
    var isBlePowerOn: any Publisher<Bool, Never> { isBlePowerOnSubject.eraseToAnyPublisher() }

    private let rssiSubject = CurrentValueSubject<Int, Never>(-200)
    var rssi: any Publisher<Int, Never> { rssiSubject.eraseToAnyPublisher() }
    
    private let connectionStateSubject = CurrentValueSubject<ConnectionState, Never>(.disconnected)
    var connectionState: any Publisher<ConnectionState, Never> { connectionStateSubject.eraseToAnyPublisher() }

    var apiProvider: PolarBleApiProvider
    
    private var lastConnectedSensor: SensorInfo?
    private var logOn = false
    private var hrBroadcastDisposable: Disposable?
    
    init(apiProvider: PolarBleApiProvider) {
        self.apiProvider = apiProvider
        Task {
            await self.apiProvider.api.logger = self
            await self.apiProvider.api.observer = self
            await self.apiProvider.api.powerStateObserver = self
            await self.apiProvider.api.deviceInfoObserver = self
        }
    }
    
    deinit {
        deinitialize()
    }

    func setStreamingState(deviceId: String) {
        stateSubject.send(SensorState.streaming(deviceId))
    }

    nonisolated private func deinitialize() {
        Task {
            await hrBroadcastDisposable?.dispose()
            await apiProvider.api.logger = nil
            await apiProvider.api.observer = nil
            await apiProvider.api.powerStateObserver = nil
            await apiProvider.api.deviceInfoObserver = nil
        }
    }
}

// MARK: - SensorConnectable

extension PolarSensorImpl: SensorConnectable {

    func connect(to sensorId: String) async throws {
        try await self.apiProvider.api.connectToDevice(sensorId)
    }
    
    func autoConnect() async throws {
        if let savedSensorId = AppSettings.shared.sensorId, !savedSensorId.isEmpty {
            try await connect(to: savedSensorId)
        }
        else {
            throw SensorError.connectionFailed
        }
    }
    
    func disconnect(removeFromStorage: Bool = true) async throws {
        if let connectedSensorId = self.lastConnectedSensor?.deviceId {
            try await apiProvider.api.disconnectFromDevice(connectedSensorId)
            if removeFromStorage {
                updateSavedSensorId(nil)
            }
        }
    }
    
    func setLogOn(_ state: Bool) {
        self.logOn = state
    }
    
    private func updateSavedSensorId(_ sensorId: String?) {
        var settings = AppSettings.shared
        settings.sensorId = sensorId
    }
    
    private func setDefaultValues() {
        batteryLevelSubject.send(UInt(0))
        rssiSubject.send(Int(-200))
    }
}

extension PolarSensorImpl {
    func startHRBroadcast() async {
        if let sensor = self.lastConnectedSensor {
            hrBroadcastDisposable?.dispose()
            hrBroadcastDisposable = await apiProvider.api.startListenForPolarHrBroadcasts([sensor.deviceId])
                .observe(on: MainScheduler.instance)
                .subscribe{ [weak self] e in
                    switch e {
                    case .completed:
                        Logger.d("Broadcast listener completed")
                    case .error(let err):
                        Logger.e("Broadcast listener failed. Reason: \(err)")
                    case .next(let broadcast):
                        Task {
                            await self?.rssiSubject.send(Int(broadcast.deviceInfo.rssi))
                        }
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

extension PolarSensorImpl: @preconcurrency PolarBleApiObserver {
    func deviceConnecting(_ identifier: PolarBleSdk.PolarDeviceInfo) {
        let sensor = SensorInfo.toSensorInfo(polarDevice: identifier)
        stateSubject.send(SensorState.connecting(sensor))
        
        Logger.d("connecting: \(identifier)")
    }
    
    func deviceConnected(_ identifier: PolarBleSdk.PolarDeviceInfo) {
        let sensor = SensorInfo.toSensorInfo(polarDevice: identifier)
        stateSubject.send(SensorState.connected(sensor))
        connectionStateSubject.send(ConnectionState.connected(sensor: sensor))
        self.lastConnectedSensor = sensor
        updateSavedSensorId(sensor.deviceId)
        Task {
            await startHRBroadcast()
        }
        
        Logger.d( "connected: \(identifier)")
    }
    
    func deviceDisconnected(_ identifier: PolarBleSdk.PolarDeviceInfo, pairingError: Bool) {
        stateSubject.send(SensorState.disconnected)
        connectionStateSubject.send(ConnectionState.disconnected)
        stopHRBroadcast()
        setDefaultValues()
        
        Logger.d( "disconnected: \(identifier)")
    }
}

// MARK: - PolarBleApiDeviceInfoObserver

extension PolarSensorImpl: @preconcurrency PolarBleApiDeviceInfoObserver {
    func batteryLevelReceived(_ identifier: String, batteryLevel: UInt) {
        self.batteryLevelSubject.send(batteryLevel)
        
        Logger.d( "batteryLevel: \(batteryLevel)")
    }
    
    func batteryChargingStatusReceived(_ identifier: String, chargingStatus: PolarBleSdk.BleBasClient.ChargeState) {}
    func disInformationReceived(_ identifier: String, uuid: CBUUID, value: String) {}
    func disInformationReceivedWithKeysAsStrings(_ identifier: String, key: String, value: String) {}
}

// MARK: - PolarBleApiPowerStateObserver

extension PolarSensorImpl: @preconcurrency PolarBleApiPowerStateObserver {
    func blePowerOn() {
        isBlePowerOnSubject.send(true)
        
        Logger.d("BLE power on")
    }
    
    func blePowerOff() {
        isBlePowerOnSubject.send(false)
        
        Logger.d( "BLE power off")
    }
}

// MARK: - PolarBleApiLogger

extension PolarSensorImpl: @preconcurrency PolarBleApiLogger {
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
