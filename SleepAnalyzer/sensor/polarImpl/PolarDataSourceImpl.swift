//
//  PolarDataSourceImpl.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 16.04.25.
//

import Foundation
import Combine
import PolarBleSdk
import RxSwift
import SwiftInjectLite

// MARK: - SensorDataSource

private actor PolarDataSourceImpl: SensorDataSource {
    
    var sensor: any Sensor

    private let hrSubject = CurrentValueSubject<UInt, Never>(0)
    var hr: any Publisher<UInt, Never> { hrSubject.eraseToAnyPublisher() }
    
    private let accSubject = CurrentValueSubject<XYZ, Never>(.default)
    var acc: any Publisher<XYZ, Never> { accSubject.eraseToAnyPublisher() }
    
    private let gyroSubject = CurrentValueSubject<XYZ, Never>(.default)
    var gyro: any Publisher<XYZ, Never> { gyroSubject.eraseToAnyPublisher() }
    
    private let ppgSubject = CurrentValueSubject<PPGArray, Never>([])
    var ppg: any Publisher<PPGArray, Never> { ppgSubject.eraseToAnyPublisher() }
    
    private let dataBundleSubject = CurrentValueSubject<DataBundle, Never>(.default)
    var dataBundle: any Publisher<DataBundle, Never> { dataBundleSubject.eraseToAnyPublisher() }
    
    var accStreamSetting: StreamSetting?
    var gyroStreamSetting: StreamSetting?
    var ppgStreamSetting: StreamSetting?
    
    private enum Config {
        static let throttleIntervalMilliseconds: Int = 2000
        static let throttleScheduler = ConcurrentDispatchQueueScheduler(qos: .background)
        static let throttleSchedulerLatestScheduler = DispatchQueue(label: "de.gun.sleepanalyzer.dataSource.throttle")
    }
    
    private var isStreaming = false
    
    private var hrDisposable: Disposable?
    private var ppgDisposable: Disposable?
    private var accDisposable: Disposable?
    private var gyroDisposable: Disposable?
    
    private var sensorState: SensorState = .disconnected
    private var disposeBag: DisposeBag = .init()
    private var cancellables: Set<AnyCancellable> = []
    
    init(sensor: any Sensor) {
        self.sensor = sensor
        
        Task {
            await self.sensor.apiProvider.api.deviceFeaturesObserver = self

            let cancellableCombineLatest = await hrSubject
                .combineLatest(
                    accSubject,
                    gyroSubject
                )
                .throttle(
                    for: .milliseconds(Config.throttleIntervalMilliseconds),
                    scheduler: Config.throttleSchedulerLatestScheduler,
                    latest: true
                )
                .sink { (hr: UInt, acc: XYZ, gyro: XYZ) in
                    Task {
                        let dataBundle = DataBundle(hr: hr, acc: acc.rmse(), gyro: gyro.rmse(), timestamp: .now)
                        await self.dataBundleSubject.send(dataBundle)
                    }
                }
            await addCancelables(cancellableCombineLatest)
            
            let cancellableConnectionState = await self.sensor.connectionState.sink { [weak self] state in
                if state == .disconnected {
                    Task {
                        await self?.stopStreaming()
                    }
                }
            }
            await addCancelables(cancellableConnectionState)
            
            let cancellableSensorState = await self.sensor.state.sink { [weak self] state in
                Task {
                    await self?.setSensorState(state)
                }
            }
            await addCancelables(cancellableSensorState)
        }
    }
    
    deinit {
        deinitialize()
    }
    
    private func addCancelables(_ cancellables: AnyCancellable) {
        self.cancellables.insert(cancellables)
    }
    
    private func cancelAllCancellables() {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
    
    private func setSensorState(_ state: SensorState) {
        sensorState = state
    }
    
    private func setAccStreamSettings(_ settings: StreamSetting?) {
        accStreamSetting = settings
    }
    
    private func setGyroStreamSettings(_ settings: StreamSetting?) {
        gyroStreamSetting = settings
    }
    
    private func setPPGStreamSettings(_ settings: StreamSetting?) {
        ppgStreamSetting = settings
    }
    
    private func setAccDisposable(_ disposable: Disposable?) {
        accDisposable = disposable
    }
    
    private func setGyroDisposable(_ disposable: Disposable?) {
        gyroDisposable = disposable
    }
    
    private func setPPGDisposable(_ disposable: Disposable?) {
        ppgDisposable = disposable
    }
    
    private nonisolated func deinitialize() {
        Task {
            await sensor.apiProvider.api.deviceFeaturesObserver = nil
            await stopStreaming()
            await cancelAllCancellables()
        }
    }
}

extension PolarDataSourceImpl {
    
    private func startStreaming(deviceId: String) async {
        await startHrStream()
        await startAccStream()
        await startGyroStream()
        await startPpgStream()
        isStreaming = true
        await sensor.setStreamingState(deviceId: deviceId)
        Logger.d("start streaming: \(deviceId)")
    }
    
    private func stopStreaming() {
        hrDisposable?.dispose()
        hrDisposable = nil
        ppgDisposable?.dispose()
        ppgDisposable = nil
        accDisposable?.dispose()
        accDisposable = nil
        gyroDisposable?.dispose()
        gyroDisposable = nil

        setDefaultValues()
        isStreaming = false
        Logger.d("stop streaming")
    }
    
    private func setDefaultValues() {
        hrSubject.send(0)
        accSubject.send(.default)
        gyroSubject.send(.default)
        ppgSubject.send(PPGArray())
    }
    
    private func getDeviceId() -> String? {
        switch sensorState {
        case .connected(let sensorInfo): return sensorInfo.deviceId
        case .streaming(let deviceId): return deviceId
        default: return nil
        }
    }
    
    private func startHrStream() async {
        if let deviceId = getDeviceId() {
            hrDisposable?.dispose()
            hrDisposable = await sensor.apiProvider.api.startHrStreaming(deviceId)
                .throttle(.milliseconds(Config.throttleIntervalMilliseconds), scheduler: Config.throttleScheduler)
                .subscribe{ [weak self] e in
                    switch e {
                    case .next(let data):
                        let value = UInt(data[0].hr)
                        Task { [weak self] in
                            await self?.hrSubject.send(value)
                        }
                    case .error(let err):
                        Logger.e("Hr stream failed: \(err)")
                    case .completed:
                        Logger.d("Hr stream completed")
                    }
                }
        } else {
            Logger.w("Device is not connected \(self.sensorState)")
        }
    }
    
    private func startAccStream() async {
        if let deviceId = getDeviceId() {
            await requestStreamSettings(deviceId: deviceId, feature: .acc) { [weak self] (settings) in
                guard let settings = settings else { return }
                Logger.d("Start acc streaming with settings: \(settings)")

                let polarSensorSetting = settings.toPolarSensorSetting()
                Task{
                    let streamSettings = polarSensorSetting.toStreamSettings()
                    await self?.setAccStreamSettings(streamSettings)
                    await self?.accDisposable?.dispose()
                    let disposable = await self?.sensor.apiProvider.api.startAccStreaming(deviceId, settings: polarSensorSetting)
                        .throttle(.milliseconds(Config.throttleIntervalMilliseconds), scheduler: Config.throttleScheduler)
                        .subscribe{ [weak self] e in
                            switch e {
                            case .next(let data):
                                if let max = data.max(by: {
                                    XYZ(x: Double($0.x), y: Double($0.y), z: Double($0.z)).rmse() < XYZ(x: Double($1.x), y: Double($1.y), z: Double($1.z)).rmse()
                                }) {
                                    let rmse = XYZ(x: Double(max.x), y: Double(max.y), z: Double(max.z))
                                    Task { [weak self] in
                                        await self?.accSubject.send(rmse)
                                    }
                                }
                            case .error(let err):
                                Logger.e("ACC stream failed: \(err)")
                            case .completed:
                                Logger.d("ACC stream completed")
                                break
                            }
                        }
                    await self?.setAccDisposable(disposable)
                }
            }
        } else {
            Logger.w("Device is not connected \(self.sensorState)")
        }
    }
    
    private func startGyroStream() async {
        if let deviceId = getDeviceId() {
            await requestStreamSettings(deviceId: deviceId, feature: .gyro) { [weak self] (settings) in
                guard let settings = settings else { return }
                Logger.d("Start gyro streaming with settings: \(settings)")

                let polarSensorSetting = settings.toPolarSensorSetting()
                Task {
                    let streamSettings = polarSensorSetting.toStreamSettings()
                    await self?.setGyroStreamSettings(streamSettings)
                    await self?.gyroDisposable?.dispose()
                    let disposable = await self?.sensor.apiProvider.api.startGyroStreaming(deviceId, settings: polarSensorSetting)
                        .throttle(.milliseconds(Config.throttleIntervalMilliseconds), scheduler: Config.throttleScheduler)
                        .subscribe{ [weak self] e in
                            switch e {
                            case .next(let data):
                                if let max = data.max(by: {
                                    XYZ(x: Double($0.x), y: Double($0.y), z: Double($0.z)).rmse() < XYZ(x: Double($1.x), y: Double($1.y), z: Double($1.z)).rmse()
                                }) {
                                    let rmse = XYZ(x: Double(max.x), y: Double(max.y), z: Double(max.z))
                                    Task { [weak self] in
                                        await self?.gyroSubject.send(rmse)
                                    }
                                }
                            case .error(let err):
                                Logger.e("Gyro stream failed: \(err)")
                            case .completed:
                                Logger.d("Gyro stream completed")
                                break
                            }
                        }
                    await self?.setGyroDisposable(disposable)
                }
            }
        } else {
            Logger.w("Device is not connected \(self.sensorState)")
        }
    }
    
    private func startPpgStream() async {
        if let deviceId = getDeviceId() {
            await requestStreamSettings(deviceId: deviceId, feature: .ppg) { [weak self] (settings) in
                guard let settings = settings else { return }
                Logger.d("Start ppg streaming with settings: \(settings)")

                let polarSensorSetting = settings.toPolarSensorSetting()
                Task {
                    let streamSettings = polarSensorSetting.toStreamSettings()
                    await self?.setPPGStreamSettings(streamSettings)
                    await self?.ppgDisposable?.dispose()
                    let disposable = await self?.sensor.apiProvider.api.startPpgStreaming(deviceId, settings: polarSensorSetting)
                        .subscribe{ [weak self] e in
                            switch e {
                            case .next(let data):
                                if(data.type == PpgDataType.ppg3_ambient1) {
                                    var ppgData: PPGArray = []
                                    for item in data.samples {
                                        // using:  ambilight = channel[3] -> channel[0] - ambilight
                                        let data = (item.timeStamp, item.channelSamples[0] - item.channelSamples[3])
                                        ppgData.append(data)
                                    }
                                    Task { [weak self] in
                                        await self?.ppgSubject.send(ppgData)
                                    }
                                }
                            case .error(let err):
                                Logger.e("PPG stream failed: \(err)")
                            case .completed:
                                Logger.d("PPG stream completed")
                            }
                        }
                    await self?.setPPGDisposable(disposable)
                }
            }
        } else {
            Logger.w("Device is not connected \(self.sensorState)")
        }
    }
}

// MARK: - Read Divice Configurations

private struct Configurations {
    var values: [PolarSensorSetting.SettingType : [UInt32]]
    
    func toPolarSensorSetting() -> PolarSensorSetting {
        var s: [PolarSensorSetting.SettingType: UInt32] = [:]
        for (key, value) in values {
            s[key] = value.first
        }
        return PolarSensorSetting(s)
    }
}

private extension PolarSensorSetting {
    
    func toStreamSettings() -> StreamSetting {
        StreamSetting(
            sampleRate: self.settings[.sampleRate]?.first,
            resolution: self.settings[.resolution]?.first,
            range: self.settings[.range]?.first,
            channels: self.settings[.channels]?.first,
        )
    }
}

private extension PolarDataSourceImpl {
    
    func requestStreamSettings(
        deviceId: String,
        feature: PolarBleSdk.PolarDeviceDataType,
        settingsHandler: @escaping (Configurations?) -> Void) async {
            await sensor.apiProvider.api.requestStreamSettings(deviceId, feature: feature)
                .observe(on: MainScheduler.instance)
                .subscribe { e in
                    switch e {
                    case .success(let settings):
                        var receivedSettings: [PolarSensorSetting.SettingType : [UInt32]] = [:]
                        for setting in settings.settings {
                            var values: [UInt32] = []
                            for settingsValue in setting.value {
                                values.append(UInt32(settingsValue))
                            }
                            receivedSettings[setting.key] = values
                        }
                        settingsHandler(Configurations(values: receivedSettings))
                        
                    case .failure(let error):
                        Logger.e("Error requesting stream settings for \(feature): \(error)")
                        settingsHandler(nil)
                    }
                }
                .disposed(by: disposeBag)
        }
}

// MARK: - PolarBleApiDeviceFeaturesObserver

extension PolarDataSourceImpl: @preconcurrency PolarBleApiDeviceFeaturesObserver {
    func bleSdkFeatureReady(_ identifier: String, feature: PolarBleSdk.PolarBleSdkFeature) {
        switch(feature) {
        case .feature_polar_online_streaming:
            if !isStreaming {
                Task {
                    await startStreaming(deviceId: identifier)
                }
            }
        default: ()
        }
    }
}

// MARK: - DI

extension InjectionRegistry {
    var sensorDataSource: any SensorDataSource {
        get {
            let sensor = Self.inject(\.sensor)
            return Self.instantiate(.singleton) { PolarDataSourceImpl(sensor: sensor) }
        }
    }
}
