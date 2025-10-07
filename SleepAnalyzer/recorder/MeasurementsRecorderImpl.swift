//
//  MeasurementsRecorderImpl.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 29.05.25.
//

import SwiftData
import SwiftUI
import Combine
import SwiftInjectLite

private actor MeasurementsRecorderImpl: MeasurementsRecorder {
    @MainActor var isRecording: Bool = false
    @MainActor var series: SeriesDTO? {
        didSet {
            isRecording = series != nil
        }
    }
    
    @Inject(\.databaseService) private var database
    @Inject(\.sensorDataSource) private var dataSource
    @Inject(\.repository) private var repository
    
    private var cancellable: AnyCancellable?
    
    init() {
        Task {
            let cancellable = await dataSource.dataBundle.sink { [weak self] dataBundle in
                Task(priority: .high) {
                    if await self?.isRecording == true {
                        await self?.record(dataBundle: dataBundle)
                    }
                }
            }
            await self.setCancellables(cancellable)
        }
    }
        
    deinit {
        cancellable?.cancel()
    }
    
    func startRecording() async throws {
        let series = SeriesDTO(startTime: .now)
        try await database.insertSeries(series: series)
        await MainActor.run {
            self.series = series
        }
    }
    
    func stopRecording(sleepQuality: SeriesDTO.SleepQuality) async throws {
        if let seriesId = await series?.id {
            try await repository.updateSeries(
                seriesId: seriesId,
                sleepQuality: sleepQuality,
                endTime: .now,
                renderParams: .init(),
                rescaleParams: AppSettings.shared.toRescaleParams()
            )
            await self.setSeries( nil)
        }
    }
    
    private func setCancellables(_ canclellable: AnyCancellable?) {
        self.cancellable = canclellable
    }
    
    @MainActor
    private func setSeries(_ series: SeriesDTO?) async {
        self.series = series
    }
    
    private func record(dataBundle: DataBundle) async {
        if let series = await series {
            do {
                try await database.insertMeasurement(dataBundle: dataBundle, seriesId: series.id)
                Logger.d("\(dataBundle)")
            } catch {
                Logger.e("Error record data: \(error)")
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
