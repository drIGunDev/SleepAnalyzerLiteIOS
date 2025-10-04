//
//  DatabaseServiceImpl.swift
//  SleepAnalyzer
//
//  Created by Dolores(chatGPT) on 28.04.25.
//

import Foundation
import SwiftData

enum EnrichmentType {
    case measurements, cache, cacheHypnogram
}

protocol DatabaseService: Actor {
    
    // --- Series ---
    func insertSeries(series: SeriesDTO) async throws
    func updateSeries(
        seriesId: UUID,
        endTime: Date?,
        maxHR: Double?,
        minHR: Double?,
        maxHRScaled: Double?,
        minHRScaled: Double?,
        graph: Data?,
        statistic: SleepPhaseStatistic?,
        sleepQuality: Int?
    ) async throws
    func deleteSeries(seriesId: UUID) async throws

    func fetchSeriesDTO(seriesId: UUID, withEnrichments: [EnrichmentType]) async throws -> SeriesDTO?
    func fetchAllSeriesDTO(order: SortOrder) async throws -> [SeriesDTO]
    
    // --- Measurement ---
    func insertMeasurement(measurement: MeasurementDTO) async throws
    func insertMeasurement(dataBundle: DataBundle, seriesId: UUID) async throws
    func deleteMeasurements(for seriesId: UUID, forced: Bool) async throws
    func fetchAllMeasurementDTO(for seriesId: UUID) async throws -> [MeasurementDTO]
    
    // --- Cache ---
    func insertCache(cache: CacheDTO) async throws
    func deleteCache(for seriesId: UUID, forced: Bool) async throws
    func fetchCacheDTO(for seriesId: UUID) async throws -> CacheDTO?

    // --- CacheHypnogram ---
    func insertCacheHypnogram(hypnogram: CacheHypnogramDTO) async throws
    func deleteCacheHypnograms(for seriesId: UUID, forced: Bool) async throws
    func fetchAllHypnogramDTO(for seriesId: UUID) async throws -> [CacheHypnogramDTO]
}
