//
//  ArchiveViewModel.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 01.06.25.
//

import SwiftUI
import SwiftInjectLite

protocol ArchiveViewModel: ObservableObject {
    var seriesArray: [SeriesDTO] { get }
    @ObservationIgnored var repository: Repository { get }
    
    func fetchAll()
    func delete(series: SeriesDTO)
}

@Observable final class ArchiveViewModelImpl: ArchiveViewModel {
    var seriesArray: [SeriesDTO] = []
    
    @ObservationIgnored @Inject(\.databaseService) private var database
    @ObservationIgnored @Inject(\.repository) var repository
    
    func fetchAll() {
        Task {
            do {
                seriesArray = try await database.fetchAllSeriesDTO(order: .reverse)
            } catch {
                Logger.e("impossible to load series: \(error)")
            }
        }
    }
    
    func delete(series: SeriesDTO) {
        Task {
            do {
                try await database.deleteSeries(seriesId: series.id)
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
        Self.instantiate(.singleton((any ArchiveViewModel).self)) { ArchiveViewModelImpl() }
    }
}
