//
//  Repository.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 18.07.25.
//

import Foundation
import SwiftInjectLite

struct CrossReportItem: Equatable {
    var time: Date
    var hrMin: Double
    var hrMax: Double
    var hrAvg: Double
    var awake: Double
    var lightSleep: Double
    var deepSleep: Double
    var rem: Double
}

protocol Repository: AnyObject {
    func rescaleHR(
        seriesId: UUID,
        renderParams: GraphRenderParams,
        rescaleParams: GraphRescaleParams,
        completion: @MainActor @escaping (Bool) -> Void
    )
    
    func rescaleAllHR(
        renderParams: GraphRenderParams,
        rescaleParams: GraphRescaleParams,
        progress: @MainActor @escaping (Int, Int) -> Void,
        cancel: @MainActor @escaping () -> Bool,
        completion: @MainActor @escaping () -> Void
    )
    
    func updateSeries(
        seriesId: UUID,
        sleepQuality: SeriesDTO.SleepQuality?,
        endTime: Date?,
        renderParams: GraphRenderParams,
        rescaleParams: GraphRescaleParams
    ) async throws
    
    func getCrossReport() async throws -> [CrossReportItem]
}

final private class RepositoryImpl: Repository {
    
    @Inject(\.databaseService) private var database
    @Inject(\.graphRenderer) var graphRender
    @Inject(\.modelConfigurationParams) private var modelParams
    @Inject(\.hypnogramComputation) private var hypnogramComp
    
    func rescaleHR(
        seriesId: UUID,
        renderParams: GraphRenderParams,
        rescaleParams: GraphRescaleParams,
        completion: @MainActor @escaping (Bool) -> Void
    ) {
        Task {
            do {
                try await updateSeries (
                    seriesId: seriesId,
                    renderParams: renderParams,
                    rescaleParams: rescaleParams
                )
                await MainActor.run { completion(true) }
            } catch let error {
                Logger.e("Error rescaleHR: \(error)")
                await MainActor.run { completion(false) }
            }
        }
    }
    
    func rescaleAllHR(
        renderParams: GraphRenderParams,
        rescaleParams: GraphRescaleParams,
        progress: @MainActor @escaping (Int, Int) -> Void,
        cancel: @MainActor @escaping () -> Bool,
        completion: @MainActor @escaping () -> Void
    ) {
        Task {
            do {
                let allSeries = try await database.fetchAllSeriesDTO(order: .reverse)
                guard !allSeries.isEmpty else {
                    await MainActor.run { completion() }
                    return
                }
                
                for (index, series) in allSeries.enumerated() {
                    try await updateSeries (
                        seriesId: series.id,
                        renderParams: renderParams,
                        rescaleParams: rescaleParams
                    )
                    
                    let canceled = await MainActor.run {
                        progress(index, allSeries.count)
                        guard !cancel() else {
                            completion()
                            return true
                        }
                        return false
                    }
                    if canceled {
                        return
                    }
                }
                
                await MainActor.run { completion() }
            } catch let error {
                Logger.e("Error bulck rescaleHR: \(error)")
                await MainActor.run { completion() }
            }
        }
    }
    
    func updateSeries (
        seriesId: UUID,
        sleepQuality: SeriesDTO.SleepQuality? = nil,
        endTime: Date? = nil,
        renderParams: GraphRenderParams,
        rescaleParams: GraphRescaleParams
    ) async throws {
        if let series = try await database.fetchSeriesDTO(seriesId: seriesId, withEnrichments: [.measurements]) {
            let bitmap = await MainActor.run {
                graphRender.render(
                    series: series,
                    renderParams: renderParams,
                    rescaleParams: rescaleParams
                )
            }
            let maxHR = Double(
                series.measurements
                    .filter { $0.heartRate > 0 }
                    .max(by: { $0.heartRate < $1.heartRate })?.heartRate ?? 0
            )
            let minHR = Double(
                series.measurements
                    .filter { $0.heartRate > 0 }
                    .min(by: { $0.heartRate < $1.heartRate })?.heartRate ?? 0
            )
            let (minHRScaled, maxHRScaled) = rescaleParams.getScale()
            let sleepPhases = hypnogramComp.createHypnogram(from: series.measurements, modelParams: modelParams)
            let statistic = SleepPhaseStatistic(sleepPhases: sleepPhases)
            try await database.updateSeries(
                seriesId: series.id,
                endTime: endTime ?? series.endTime,
                maxHR: maxHR,
                minHR: minHR,
                maxHRScaled: maxHRScaled ?? maxHR,
                minHRScaled: minHRScaled ?? minHR,
                graph: bitmap,
                statistic: statistic,
                sleepQuality: sleepQuality?.rawValue ?? series.sleepQuality
            )
        }
    }
    
    func getCrossReport() async throws -> [CrossReportItem] {
        let allSeries = try await database.fetchAllSeriesDTO(order: .reverse)
        guard !allSeries.isEmpty else { return [] }
        
        var result: [CrossReportItem] = []
        
        for series in allSeries {
            if let series = try await database.fetchSeriesDTO(seriesId: series.id, withEnrichments: [.cache]),
               let cache = series.cache {
                let report = CrossReportItem(
                    time: series.startTime,
                    hrMin: Double(cache.minHR),
                    hrMax: Double(cache.maxHR),
                    hrAvg: Double(cache.maxHR == cache.minHR ? 0 : (cache.maxHR + cache.minHR) / 2),
                    awake: Double(cache.awake),
                    lightSleep: Double(cache.lSeep),
                    deepSleep: Double(cache.dSleep),
                    rem: Double(cache.rem)
                )
                result.append(report)
            }
        }
        
        return result
    }
}

// MARK: - DI

extension InjectionRegistry {
    var repository: any Repository { Self.instantiate(.factory) { RepositoryImpl.init() } }
}
