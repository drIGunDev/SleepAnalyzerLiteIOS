//
//  CellViewModel.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 12.06.25.
//

import SwiftUI
import SwiftInjectLite

protocol ArchiveCellViewModel: ObservableObject {
    var series: SeriesDTO? { get set }
    var image: UIImage? { get }
    var sleepStatistic: SleepPhaseStatistic? { get }
    var refreshImageId: String { get }
    var refreshGraphId: String { get }
    
    func getMeasurements() -> [MeasurementDTO]
    func enrichSeries()
}

@Observable final class ArchiveCellViewModelImpl: ArchiveCellViewModel {
    var series: SeriesDTO?
    var image: UIImage?
    var sleepStatistic: SleepPhaseStatistic?
    var refreshImageId: String = UUID().uuidString
    var refreshGraphId: String = UUID().uuidString
    
    @ObservationIgnored @Inject(\.databaseService) private var database
    
    func getMeasurements() -> [MeasurementDTO] { series?.measurements ?? [] }
    
    func enrichSeries() {
        guard let seriesId = series?.id else {
            Logger.e("Invalid series id")
            return
        }
        
        guard series?.cache?.bitmap == nil else {
            invalidateImage()
            return
        }

        Task {
            do {
                if let series = try await database.fetchSeriesDTO(seriesId: seriesId, withEnrichments: [.cache]) {
                    sleepStatistic = series.cache?.toSleepStatistic()
                    if let bitmap = series.cache?.bitmap {
                        image = createImage(bitmap: bitmap)
                        self.series = series
                        await MainActor.run {
                            invalidateImage()
                        }
                    }
                    else {
                        self.series = try await database.fetchSeriesDTO(seriesId: seriesId, withEnrichments: [.measurements])
                        await MainActor.run {
                            invalidateGraph()
                        }
                    }
                }
                else {
                    Logger.e("impossible to enrich series")
                }
            } catch {
                Logger.e("impossible to enrich series: \(error)")
            }
        }
    }
    
    private func invalidateImage() {
        refreshImageId = UUID().uuidString
    }
    
    private func invalidateGraph() {
        refreshGraphId = UUID().uuidString
    }
    
    private func createImage(bitmap: Data?) -> UIImage? {
        return UIImage(data: bitmap ?? Data())
    }
}
