//
//  ArchiveViewModel.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 01.06.25.
//

import SwiftUI
import SwiftInjectLite

protocol ArchiveViewModel: ObservableObject, AnyObject {
    var seriesArray: [UpdatableWrapper<SeriesDTO>] { get }
    @ObservationIgnored var repository: Repository { get }
    
    func fetchAll()
    func delete(series: UpdatableWrapper<SeriesDTO>)
}

@Observable final private class ArchiveViewModelImpl: ArchiveViewModel {
    var seriesArray: [UpdatableWrapper<SeriesDTO>] = []
    @ObservationIgnored @Inject(\.repository) var repository

    @ObservationIgnored @Inject(\.databaseService) private var database
    
    func fetchAll() {
        Task {
            do {
                seriesArray = try await database
                    .fetchAllSeriesDTO(order: .reverse)
                    .mapToUpdatableWrappers()
            } catch {
                Logger.e("impossible to load series: \(error)")
            }
        }
    }
    
    func delete(series: UpdatableWrapper<SeriesDTO>) {
        Task {
            do {
                try await database
                    .deleteSeries(seriesId: series.wrappedValue.id)
                await MainActor.run {
                    withAnimation {
                        seriesArray.remove(series)
                    }
                }
            } catch {
                Logger.e("impossible to delete series: \(error)")
            }
        }
    }
}

// MARK: - DI

extension InjectionRegistry {
    var archiveViewModel: any ArchiveViewModel {
        Self.instantiate(.singleton) { ArchiveViewModelImpl() }
    }
}
