//
//  RecorderImpl.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 29.05.25.
//

import SwiftData
import SwiftUI
import Combine
import SwiftInjectLite

final private class MeasurementsRecorderImpl: MeasurementsRecorder {
    var isRecording: Bool = false
    
    var series: SeriesDTO? {
        didSet {
            isRecording = series != nil
        }
    }
    
    @Inject(\.databaseService) private var database
    @Inject(\.sensorDataSource) private var dataSource
    @Inject(\.repository) private var repository
    
    private var cancellables: Set<AnyCancellable> = []
    
    init() {
        Task {
            await dataSource.dataBundle.sink { [weak self] dataBundle in
                if self?.isRecording == true {
                    self?.record(dataBundle: dataBundle)
                }
            }
            .store(in: &cancellables)
        }
    }
        
    func startRecording() async throws {
        let series = SeriesDTO(startTime: .now)
        try await database.insertSeries(series: series)
        self.series = series
    }
    
    func stopRecording(sleepQuality: SeriesDTO.SleepQuality) async throws {
        if let seriesId = series?.id {
            try await repository.updateSeries(
                seriesId: seriesId,
                sleepQuality: sleepQuality,
                endTime: .now,
                renderParams: .init(),
                rescaleParams: AppSettings.shared.toRescaleParams()
            )
            self.series = nil
        }
    }
    
    private func record(dataBundle: DataBundle) {
        Task (priority: .high) {
            if let series = series {
                do {
                    try await database.insertMeasurement(dataBundle: dataBundle, seriesId: series.id)
                    Logger.d("\(dataBundle)")
                } catch {
                    Logger.e("Error record data: \(error)")
                }
            }
        }
    }
}

// MARK: - DI

extension InjectionRegistry {
    var measurementsRecorder: any MeasurementsRecorder {
        Self.instantiate(.singleton) { MeasurementsRecorderImpl() }
    }
}
