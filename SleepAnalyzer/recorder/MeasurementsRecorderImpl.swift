//
//  RecorderImpl.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 29.05.25.
//

import SwiftData
import SwiftUI
import SwiftInjectLite

final class MeasurementsRecorderImpl: MeasurementsRecorder {
    var isRecording: Bool = false
    
    var series: SeriesDTO? {
        didSet {
            isRecording = series != nil
        }
    }
    
    @Inject(\.databaseService) private var database
    @Inject(\.sensorDataSource) private var dataSource
    @Inject(\.repository) private var repository
    
    private var dataBundleSubscriberId: UUID?
    
    init() {
        self.dataBundleSubscriberId = dataSource.dataBundleCombinedLatest.subscribe { [weak self] dataBundle in
            if self?.isRecording == true {
                self?.record(dataBundle: dataBundle)
            }
        }
    }
    
    deinit {
        if let subscripton = dataBundleSubscriberId {
            dataSource.dataBundleCombinedLatest.unsubscribe(subscripton)
        }
    }
    
    func startRecording() {
        Task {
            let series = SeriesDTO(startTime: .now)
            try? await database.insertSeries(series: series)
            self.series = series
        }
    }
    
    func stopRecording(sleepQuality: SeriesDTO.SleepQuality) {
        Task {
            if let seriesId = series?.id {
                try? await repository.updateSeries(
                    seriesId: seriesId,
                    sleepQuality: sleepQuality,
                    endTime: .now,
                    renderParams: .init(),
                    rescaleParams: AppSettings.shared.toRescaleParams()
                )
                self.series = nil
            }
        }
    }
    
    private func record(dataBundle: DataBundle) {
        Task (priority: .high) {
            if let series = series {
                try? await database.insertMeasurement(dataBundle: dataBundle, seriesId: series.id)
                Logger.d("\(dataBundle)")
            }
        }
    }
}

// MARK: - DI

extension InjectionRegistry {
    var measurementsRecorder: any MeasurementsRecorder {
        Self.instantiate(.singleton(MeasurementsRecorder.self)) { MeasurementsRecorderImpl() }
    }
}
