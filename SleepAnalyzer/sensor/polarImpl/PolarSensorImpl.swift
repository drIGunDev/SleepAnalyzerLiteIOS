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

    let state: any Publisher<SensorState, Never> = CurrentValueSubject(.disconnected)
    let batteryLevel: any Publisher<UInt, Never> = CurrentValueSubject(0)
    let isBlePowerOn: any Publisher<Bool, Never> = CurrentValueSubject(false)
    let rssi: any Publisher<Int, Never> = CurrentValueSubject(-200)
    
    var apiProvider: PolarBleApiProvider
    
    var connectionState: any Publisher<ConnectionState, Never> = CurrentValueSubject(.disconnected)
    
    private var connectedSensor: SensorInfo?

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
        state.asCurrentValueSubject().send(SensorState.streaming(deviceId))
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
        if let connectedSensorId = self.connectedSensor?.deviceId {
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
        batteryLevel.asCurrentValueSubject().send(UInt(0))
        rssi.asCurrentValueSubject().send(Int(-200))
    }
}

extension PolarSensorImpl {
    func startHRBroadcast() async {
        if let sensor = self.connectedSensor {
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
                            await self?.rssi.asCurrentValueSubject().send(Int(broadcast.deviceInfo.rssi))
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
        state.asCurrentValueSubject().send(SensorState.connecting(sensor))
        Logger.d("connecting: \(identifier)")
    }
    
    func deviceConnected(_ identifier: PolarBleSdk.PolarDeviceInfo) {
        let sensor = SensorInfo.toSensorInfo(polarDevice: identifier)
        state.asCurrentValueSubject().send(SensorState.connected(sensor))
        connectionState.asCurrentValueSubject().send(ConnectionState.connected(sensor: sensor))
        self.connectedSensor = sensor
        updateSavedSensorId(sensor.deviceId)
        Task {
            await startHRBroadcast()
        }
        
        Logger.d( "connected: \(identifier)")
    }
    
    func deviceDisconnected(_ identifier: PolarBleSdk.PolarDeviceInfo, pairingError: Bool) {
        state.asCurrentValueSubject().send(SensorState.disconnected)
        connectionState.asCurrentValueSubject().send(ConnectionState.disconnected)
        stopHRBroadcast()
        setDefaultValues()
        self.connectedSensor = nil
        
        Logger.d( "disconnected: \(identifier)")
    }
}

// MARK: - PolarBleApiDeviceInfoObserver

extension PolarSensorImpl: @preconcurrency PolarBleApiDeviceInfoObserver {
    func batteryLevelReceived(_ identifier: String, batteryLevel: UInt) {
        self.batteryLevel.asCurrentValueSubject().send(batteryLevel)
        
        Logger.d( "batteryLevel: \(batteryLevel)")
    }
    
    func batteryChargingStatusReceived(_ identifier: String, chargingStatus: PolarBleSdk.BleBasClient.ChargeState) {}
    func disInformationReceived(_ identifier: String, uuid: CBUUID, value: String) {}
    func disInformationReceivedWithKeysAsStrings(_ identifier: String, key: String, value: String) {}
}

// MARK: - PolarBleApiPowerStateObserver

extension PolarSensorImpl: @preconcurrency PolarBleApiPowerStateObserver {
    func blePowerOn() {
        isBlePowerOn.asCurrentValueSubject().send(true)
        
        Logger.d("BLE power on")
    }
    
    func blePowerOff() {
        isBlePowerOn.asCurrentValueSubject().send(false)
        
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
