//
//  TrackingViewModel.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 02.06.25.
//

import SwiftUI
import Combine
import SwiftInjectLite

protocol TrackingViewModel: ObservableObject {
    var series: SeriesDTO? { get set }
    var sleepPhase: [SleepPhase] { get }
    
    func startTracking()
    func stopTracking(sleepQuality: SeriesDTO.SleepQuality)
    
    func startUpdateSeries()
    func stopUpdateSeries()
}

@Observable final class TrackingViewModelImpl: TrackingViewModel {
    var series: SeriesDTO?
    var sleepPhase: [SleepPhase] = []
    
    private enum Config {
        static let seriesUpdateTimeInterval: TimeInterval = 8
    }
    
    @ObservationIgnored private var currentRecordedSeries: SeriesDTO? {
        return recorder.series
    }
    
    @ObservationIgnored @Inject(\.measurementsRecorder) private var recorder
    @ObservationIgnored @Inject(\.databaseService) private var database
    @ObservationIgnored @Inject(\.sensorDataSource) private var dataSource
    @ObservationIgnored @Inject(\.modelConfigurationParams) private var modelParams
    @ObservationIgnored @Inject(\.hypnogramComputation) private var hypnogramComp
    
    @ObservationIgnored private var updateSeries: Bool = true
    @ObservationIgnored private let timer = Timer.publish(every: Config.seriesUpdateTimeInterval, on: .main, in: .common).autoconnect()
    @ObservationIgnored private var cancellables: Set<AnyCancellable> = []
    
    init() {
        timer
            .sink { [weak self] _ in
                if self?.recorder.isRecording == true && self?.updateSeries == true {
                    self?.fetchSeries()
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
        }
    }
    
    func stopTracking(sleepQuality: SeriesDTO.SleepQuality) {
        Task {
            try? await recorder.stopRecording(sleepQuality: sleepQuality)
        }
    }
    
    func startUpdateSeries() {
        updateSeries = true
    }
    func stopUpdateSeries() {
        updateSeries = false
    }

    private func fetchSeries() {
        Task {
            if let seriesId = currentRecordedSeries?.id {
                self.series = try? await database.fetchSeriesDTO(seriesId: seriesId, withEnrichments: [.measurements])
            }
            
            if let series = self.series {
                self.sleepPhase = hypnogramComp.createHypnogram(from: series.measurements, modelParams: modelParams)
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

