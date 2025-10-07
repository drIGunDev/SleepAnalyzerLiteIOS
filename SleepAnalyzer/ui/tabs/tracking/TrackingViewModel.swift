//
//  TrackingViewModel.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 02.06.25.
//

import SwiftUI
import Combine
import SwiftInjectLite

protocol TrackingViewModel: ObservableObject, AnyObject {
    @ObservationIgnored @MainActor var sensor: Sensor { get }
    var sensorId: String? { get set }
    var sensorBatteryLevel: UInt { get set }
    var sensorRSSI: Int { get set }
    var sensorState: SensorState { get set }
    var sensorIsConnected: Bool { get set }
    var hr: UInt { get set }
    var series: SeriesDTO? { get set }
    var hypnogramTrackingViewModel: any HypnogramTrackingViewModel { get set }
    var ppgViewModel: any PPGViewModel { get set }
    
    func startTracking()
    func stopTracking(sleepQuality: SeriesDTO.SleepQuality)
    
    @MainActor func startUIUpdate()
    @MainActor func stopUIUpdate()
}

@Observable final private class TrackingViewModelImpl: TrackingViewModel {
    var sensor: Sensor { sensorDataSource.sensor }
    var sensorId: String?
    var sensorBatteryLevel: UInt = 0
    var sensorRSSI: Int = 0
    var sensorState: SensorState = .disconnected
    var sensorIsConnected: Bool = false
    var hr: UInt = 0
    var series: SeriesDTO?
    var hypnogramTrackingViewModel = InjectionRegistry.inject(\.hypnogramTrackingViewModel)
    var ppgViewModel = InjectionRegistry.inject(\.ppgViewModel)
    
    @ObservationIgnored @Inject(\.sensorDataSource) private var sensorDataSource

    private enum Config {
        static let seriesUpdateTimeInterval: TimeInterval = 8
    }
    
    @ObservationIgnored @MainActor private var currentRecordedSeries: SeriesDTO? {
        return recorder.series
    }
    
    @ObservationIgnored @Inject(\.measurementsRecorder) private var recorder
    @ObservationIgnored @Inject(\.databaseService) private var database
    @ObservationIgnored @Inject(\.modelConfigurationParams) private var modelParams
    @ObservationIgnored @Inject(\.hypnogramComputation) private var hypnogramComp
    
    @ObservationIgnored private var isUIUpdate = true
    @ObservationIgnored private let timer = Timer
        .publish(every: Config.seriesUpdateTimeInterval, on: .main, in: .common)
        .autoconnect()
    @ObservationIgnored private var cancellables: Set<AnyCancellable> = []
    
    init() {
        Task {
            await sensorDataSource.sensor.state
                .sink { [weak self] state in
                    switch state {
                    case .disconnected:
                        self?.sensorId = nil
                        self?.sensorState = .disconnected
                        self?.sensorIsConnected = false
                    case let .connecting(sensorInfo):
                        self?.sensorId = sensorInfo.deviceId
                        self?.sensorState = .connecting(sensorInfo)
                        self?.sensorIsConnected = true
                    case let .connected(sensorInfo):
                        self?.sensorId = sensorInfo.deviceId
                        self?.sensorState = .connected(sensorInfo)
                        self?.sensorIsConnected = true
                    case let .streaming(deviceId):
                        self?.sensorId = deviceId
                        self?.sensorState = .streaming(deviceId)
                        self?.sensorIsConnected = true
                    }
                }
                .store(in: &cancellables)
            
            await sensorDataSource.hr
                .assign(to: \.self.hr, on: self)
                .store(in: &cancellables)
            
            await sensorDataSource.sensor.batteryLevel
                .assign(to: \.self.sensorBatteryLevel, on: self)
                .store(in: &cancellables)
            
            await sensorDataSource.sensor.rssi
                .assign(to: \.self.sensorRSSI, on: self)
                .store(in: &cancellables)
        }
        
        timer
            .sink { [weak self] _ in
                Task {
                    if await self?.recorder.isRecording == true && self?.isUIUpdate == true {
                        self?.fetchSeries()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    deinit {
        timer.upstream.connect().cancel()
    }
    
    func startTracking() {
        Task {
            try? await recorder.startRecording()
            hypnogramTrackingViewModel.startTracking(startTime: .now)
        }
    }
    
    func stopTracking(sleepQuality: SeriesDTO.SleepQuality) {
        Task {
            try? await recorder.stopRecording(sleepQuality: sleepQuality)
            hypnogramTrackingViewModel.stopTracking()
        }
    }
    
    func startUIUpdate() {
        isUIUpdate = true
        ppgViewModel.subscribe()
    }
    
    func stopUIUpdate() {
        isUIUpdate = false
        ppgViewModel.unsubscribe()
    }

    private func updateHypnogram(sleepPhase: [SleepPhase]) {
        hypnogramTrackingViewModel.hypnogramViewModel.updateTracking(sleepPhases: sleepPhase)
    }
    
    private func fetchSeries() {
        Task {
            if let seriesId = await currentRecordedSeries?.id {
                self.series = try? await database.fetchSeriesDTO(seriesId: seriesId, withEnrichments: [.measurements])
            }
            
            if let series = self.series {
                let sleepPhase = hypnogramComp.createHypnogram(from: series.measurements, modelParams: modelParams)
                updateHypnogram(sleepPhase: sleepPhase)
            }
        }
    }
}

// MARK: - DI

extension InjectionRegistry {
    var trackingViewModel: any TrackingViewModel {
        Self.instantiate(.factory) { TrackingViewModelImpl() }
    }
}
