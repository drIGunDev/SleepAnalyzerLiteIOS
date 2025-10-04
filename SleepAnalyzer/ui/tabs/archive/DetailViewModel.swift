//
//  DetailViewModel.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 23.06.25.
//

import Foundation
import SwiftUI
import SwiftInjectLite

protocol DetailViewModel: ObservableObject, AnyObject {
    var series: SeriesDTO? { get set }
    
    @ObservationIgnored var hypnogramComp: any HypnogramComputation { get }
    
    func getMeasurements() -> [MeasurementDTO]
    func enrich()
}

@Observable final private class DetailViewModelImpl: DetailViewModel {
    var series: SeriesDTO?
    
    @ObservationIgnored @Inject(\.databaseService) private var database
    @ObservationIgnored @Inject(\.hypnogramComputation) var hypnogramComp
    
    func getMeasurements() -> [MeasurementDTO] { series?.measurements ?? [] }
    
    func enrich() {
        Task {
            do {
                if let seriesId = series?.id {
                    self.series = try await database.fetchSeriesDTO(seriesId: seriesId, withEnrichments: [.cache, .measurements])
                }
            } catch {
                Logger.e("impossible to enrich series: \(error)")
            }
        }
    }
}

// MARK: - DI

extension InjectionRegistry {
    var detailViewModel: any DetailViewModel { Self.instantiate(.factory) { DetailViewModelImpl.init() } }
}
