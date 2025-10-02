//
//  PolarDataSourceImpl.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 16.04.25.
//

import Foundation
import SwiftUI
import Combine
import PolarBleSdk
import RxSwift
import RxRelay
import SwiftInjectLite

// MARK: - API

// MARK: - SensorDataSource

@Observable final class PolarDataSourceImpl: SensorDataSource {
    
    var sensor: any Sensor
    
    var hr: UInt = 0
    var acc: XYZ = .init(x: 0, y: 0, z: 0)
    var ppg: PPGArray = []
    var gyro: XYZ = .init(x: 0, y: 0, z: 0)
    var timestamp: Date = .now
    var accStreamSetting: StreamSetting = .init()
    var gyroStreamSetting: StreamSetting = .init()
    var ppgStreamSetting: StreamSetting = .init()
    
    @ObservationIgnored var dataBundleSubject: any Publisher<DataBundle, Never> = PassthroughSubject()
    @ObservationIgnored var ppgDataSubject: any Publisher<PPGArray, Never> = PassthroughSubject()
    
    private enum Config {
        static let throttleIntervalMilliseconds: Int = 2000
        static let throttleScheduler = ConcurrentDispatchQueueScheduler(qos: .background)
    }
    
    @ObservationIgnored private var isStreaming = false
    @ObservationIgnored private var hrDisposable: Disposable?
    @ObservationIgnored private var ppgDisposable: Disposable?
    @ObservationIgnored private var accDisposable: Disposable?
    @ObservationIgnored private var gyroDisposable: Disposable?
    
    @ObservationIgnored private let hrRelay: BehaviorRelay<UInt> = BehaviorRelay(value: 0)
    @ObservationIgnored private let accRelay: BehaviorRelay<Double> = BehaviorRelay(value: 0)
    @ObservationIgnored private let gyroRelay: BehaviorRelay<Double> = BehaviorRelay(value: 0)
    
    @ObservationIgnored private var dataBundleCombinedLatest: Observable<DataBundle> {
        return Observable
            .combineLatest(hrRelay.asObservable(), accRelay.asObservable(), gyroRelay.asObservable()) { hr, acc, gyro in
                return DataBundle(hr: hr, acc: acc, gyro: gyro, timestamp: .now)
            }
    }
    
    @ObservationIgnored private var disposeBag: DisposeBag = .init()
    
    init(sensor: any Sensor) {
        self.sensor = sensor
        self.sensor.connectionDelegate = self
        self.sensor.apiProvider.api.deviceFeaturesObserver = self
        
        dataBundleCombinedLatest
            .throttle(.milliseconds(Config.throttleIntervalMilliseconds), scheduler: Config.throttleScheduler)
            .subscribe(onNext: { [weak self] dataBundle in
                (self?.dataBundleSubject as? PassthroughSubject<DataBundle, Never>)?.send(dataBundle)
            })
            .disposed(by: disposeBag)
    }
    
    deinit {
        stopStreaming()
        self.sensor.connectionDelegate = nil
        self.sensor.apiProvider.api.deviceFeaturesObserver = nil
    }
}

extension PolarDataSourceImpl {
    private func startStreaming(deviceId: String) {
        startHrStreaming()
        startAccStreaming()
        startGyroStreaming()
        startPpgStream()
        self.isStreaming = true
        self.sensor.setStreamingState(deviceId: deviceId)
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
        
        self.setDefaultValues()
        self.isStreaming = false
        hrRelay.accept(0)
        accRelay.accept(0)
        gyroRelay.accept(0)
        Logger.d("stop streaming")
    }
    
    private func setDefaultValues() {
        self.hr = 0
        self.acc = .init(x: 0, y: 0, z: 0)
        self.gyro = .init(x: 0, y: 0, z: 0)
        self.ppg = []
        self.timestamp = .now
    }
    
    private func getDeviceId() -> String? {
        switch sensor.state {
        case .connected(let sensorInfo): return sensorInfo.deviceId
        case .streaming(let deviceId): return deviceId
        default: return nil
        }
    }
    
    private func startHrStreaming() {
        if let deviceId = getDeviceId() {
            hrDisposable?.dispose()
            hrDisposable = sensor.apiProvider.api.startHrStreaming(deviceId)
                .throttle(.milliseconds(Config.throttleIntervalMilliseconds), scheduler: Config.throttleScheduler)
                .subscribe{ [weak self] e in
                    switch e {
                    case .next(let data):
                        let value = UInt(data[0].hr)
                        self?.hrRelay.accept(value)
                        self?.timestamp = .now
                        self?.hr = value
                    case .error(let err):
                        Logger.e("Hr stream failed: \(err)")
                    case .completed:
                        Logger.d("Hr stream completed")
                    }
                }
        } else {
            Logger.w("Device is not connected \(self.sensor.state)")
        }
    }
    
    private func startAccStreaming() {
        if let deviceId = getDeviceId() {
            requestStreamSettings(deviceId: deviceId, feature: .acc) { [weak self] (settings) in
                guard let settings = settings else { return }
                Logger.d("Start acc streaming with settings: \(settings)")
                
                let polarSensorSetting = settings.toPolarSensorSetting()
                self?.accStreamSetting = polarSensorSetting.toStreamSettings()
                self?.accDisposable?.dispose()
                self?.accDisposable = self?.sensor.apiProvider.api.startAccStreaming(deviceId, settings: polarSensorSetting)
                    .throttle(.milliseconds(Config.throttleIntervalMilliseconds), scheduler: Config.throttleScheduler)
                    .subscribe{ [weak self] e in
                        switch e {
                        case .next(let data):
                            if let max = data.max(by: {
                                XYZ(x: Double($0.x), y: Double($0.y), z: Double($0.z)).rmse() < XYZ(x: Double($1.x), y: Double($1.y), z: Double($1.z)).rmse()
                            }) {
                                let rmse = XYZ(x: Double(max.x), y: Double(max.y), z: Double(max.z))
                                self?.accRelay.accept(rmse.rmse())
                                self?.acc = rmse
                            }
                        case .error(let err):
                            Logger.e("ACC stream failed: \(err)")
                        case .completed:
                            Logger.d("ACC stream completed")
                            break
                        }
                    }
            }
        } else {
            Logger.w("Device is not connected \(self.sensor.state)")
        }
    }
    
    private func startGyroStreaming() {
        if let deviceId = getDeviceId() {
            requestStreamSettings(deviceId: deviceId, feature: .gyro) { [weak self] (settings) in
                guard let settings = settings else { return }
                Logger.d("Start gyro streaming with settings: \(settings)")
                
                let polarSensorSetting = settings.toPolarSensorSetting()
                self?.gyroStreamSetting = polarSensorSetting.toStreamSettings()
                self?.gyroDisposable?.dispose()
                self?.gyroDisposable = self?.sensor.apiProvider.api.startGyroStreaming(deviceId, settings: polarSensorSetting)
                    .throttle(.milliseconds(Config.throttleIntervalMilliseconds), scheduler: Config.throttleScheduler)
                    .subscribe{ [weak self] e in
                        switch e {
                        case .next(let data):
                            if let max = data.max(by: {
                                XYZ(x: Double($0.x), y: Double($0.y), z: Double($0.z)).rmse() < XYZ(x: Double($1.x), y: Double($1.y), z: Double($1.z)).rmse()
                            }) {
                                let rmse = XYZ(x: Double(max.x), y: Double(max.y), z: Double(max.z))
                                self?.gyroRelay.accept(rmse.rmse())
                                self?.gyro = rmse
                            }
                        case .error(let err):
                            Logger.e("Gyro stream failed: \(err)")
                        case .completed:
                            Logger.d("Gyro stream completed")
                            break
                        }
                    }
            }
        } else {
            Logger.w("Device is not connected \(self.sensor.state)")
        }
    }
    
    private func startPpgStream() {
        if let deviceId = getDeviceId() {
            requestStreamSettings(deviceId: deviceId, feature: .ppg) { [weak self] (settings) in
                guard let settings = settings else { return }
                Logger.d("Start ppg streaming with settings: \(settings)")
                
                let polarSensorSetting = settings.toPolarSensorSetting()
                self?.ppgStreamSetting = polarSensorSetting.toStreamSettings()
                self?.ppgDisposable?.dispose()
                self?.ppgDisposable = self?.sensor.apiProvider.api.startPpgStreaming(deviceId, settings: polarSensorSetting)
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
                                (self?.ppgDataSubject as? PassthroughSubject<PPGArray, Never>)?.send(ppgData)
                                self?.ppg.removeAll()
                                self?.ppg.append(contentsOf: ppgData)
                            }
                        case .error(let err):
                            Logger.e("PPG stream failed: \(err)")
                        case .completed:
                            Logger.d("PPG stream completed")
                        }
                    }
            }
        } else {
            Logger.w("Device is not connected \(self.sensor.state)")
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
        settingsHandler: @escaping (Configurations?) -> Void) {
            sensor.apiProvider.api.requestStreamSettings(deviceId, feature: feature)
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

// MARK: - ConnectionDelegate

extension PolarDataSourceImpl: ConnectionDelegate {
    func onConnected(sensor: SensorInfo) {}
    
    func onDisconnected() {
        stopStreaming()
    }
}

// MARK: - PolarBleApiDeviceFeaturesObserver

extension PolarDataSourceImpl: PolarBleApiDeviceFeaturesObserver {
    func bleSdkFeatureReady(_ identifier: String, feature: PolarBleSdk.PolarBleSdkFeature) {
        switch(feature) {
        case .feature_polar_online_streaming:
            if !isStreaming {
                startStreaming(deviceId: identifier)
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
