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
    var series: SeriesDTO? { get set }
    var hypnogramTrackingViewModel: any HypnogramTrackingViewModel { get set }
    
    func startTracking()
    func stopTracking(sleepQuality: SeriesDTO.SleepQuality)
    
    func startUIUpdate()
    func stopUIUpdate()
}

@Observable final private class TrackingViewModelImpl: TrackingViewModel {
    var series: SeriesDTO?
    
    var hypnogramTrackingViewModel = InjectionRegistry.inject(\.hypnogramTrackingViewModel)
    
    private enum Config {
        static let seriesUpdateTimeInterval: TimeInterval = 8
    }
    
    @ObservationIgnored private var currentRecordedSeries: SeriesDTO? {
        return recorder.series
    }
    
    @ObservationIgnored @Inject(\.measurementsRecorder) private var recorder
    @ObservationIgnored @Inject(\.databaseService) private var database
    @ObservationIgnored @Inject(\.modelConfigurationParams) private var modelParams
    @ObservationIgnored @Inject(\.hypnogramComputation) private var hypnogramComp
    
    @ObservationIgnored private var isUIUpdate = true
    @ObservationIgnored private let timer = Timer.publish(every: Config.seriesUpdateTimeInterval, on: .main, in: .common).autoconnect()
    @ObservationIgnored private var cancellables: Set<AnyCancellable> = []
    
    init() {
        timer
            .sink { [weak self] _ in
                if self?.recorder.isRecording == true && self?.isUIUpdate == true {
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
    }
    func stopUIUpdate() {
        isUIUpdate = false
    }

    private func updateHypnogram(sleepPhase: [SleepPhase]) {
        hypnogramTrackingViewModel.hypnogramViewModel.updateTracking(sleepPhases: sleepPhase)
    }
    
    private func fetchSeries() {
        Task {
            if let seriesId = currentRecordedSeries?.id {
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

