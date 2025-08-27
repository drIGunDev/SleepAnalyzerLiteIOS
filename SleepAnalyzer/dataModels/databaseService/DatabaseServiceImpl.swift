//
//  DatabaseService.swift
//  SleepAnalyzer
//
//  Created by Dolores(chatGPT) on 28.04.25.
//

import Foundation
import SwiftData
import CoreData
import SwiftUI
import SwiftInjectLite

actor DatabaseServiceImpl: DatabaseService, ModelActor {
    
    private let modelContext: ModelContext
    
    nonisolated let modelExecutor: any ModelExecutor
    nonisolated let modelContainer: ModelContainer = {
        do {
            let storeURL = URL.documentsDirectory.appending(path: "sleep-analyzer.sqlite")
            let schema = Schema(
                [
                    Series.self,
                    Measurement.self,
                    Cache.self,
                    CacheHypnogram.self
                ]
            )
            let config = ModelConfiguration(schema: schema, url: storeURL)
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()
    
    init() {
        self.modelContext = ModelContext(modelContainer)
        self.modelExecutor = DefaultSerialModelExecutor(modelContext: modelContext)
    }
    
    // --- Series ---
    
    func insertSeries(series: SeriesDTO) throws {
        let series = Series(series: series)
        try insertSeries(series)
    }
    
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
    ) throws {
        if let series = try fetchSeries(seriesId: seriesId) {
            try updateSeries(
                series: series,
                endTime: endTime,
                maxHR: maxHR,
                minHR: minHR,
                maxHRScaled: maxHRScaled,
                minHRScaled: minHRScaled,
                graph: graph,
                statistic: statistic,
                sleepQuality: sleepQuality
            )
        }
    }
    
    func deleteSeries(seriesId: UUID) throws {
        do {
            if let series = try fetchSeries(seriesId: seriesId) {
                try deleteSeries(series, forced: false)
                try deleteMeasurements(for: seriesId, forced: false)
                try deleteCache(for: seriesId, forced: false)
                try deleteCacheHypnograms(for: seriesId, forced: false)
                try modelContext.save()
            }
        } catch {
            modelContext.rollback()
            throw error
        }
    }
    
    func fetchSeriesDTO(seriesId: UUID, withEnrichments: [EnrichmentType]) throws -> SeriesDTO? {
        guard var series = try fetchSeries(seriesId: seriesId)?.toDTO() else { return nil }
        
        try enrichSeriesDTO(&series, withEnrichments: withEnrichments)
        return series
    }
    
    func fetchAllSeriesDTO(order: SortOrder) throws -> [SeriesDTO] {
        let series = try fetchAllSeries(order: order)
        return series.map { SeriesDTO.from(series: $0) }
    }
    
    private func enrichSeriesDTO(_ seriesDTO: inout SeriesDTO, withEnrichments: [EnrichmentType]) throws {
        if withEnrichments.contains(.cache) {
            seriesDTO.cache = try fetchCacheDTO(for: seriesDTO.id)
        }
        if withEnrichments.contains(.measurements) {
            seriesDTO.measurements = try fetchAllMeasurementDTO(for: seriesDTO.id)
        }
        if withEnrichments.contains(.cacheHypnogram) {
            seriesDTO.cacheHypnograms = try fetchAllHypnogramDTO(for: seriesDTO.id)
        }
    }
    
    private func insertSeries(_ series: Series) throws {
        modelContext.insert(series)
        try modelContext.save()
    }
    
    private func updateSeries(
        series: Series,
        endTime: Date?,
        maxHR: Double?,
        minHR: Double?,
        maxHRScaled: Double?,
        minHRScaled: Double?,
        graph: Data?,
        statistic: SleepPhaseStatistic?,
        sleepQuality: Int?
    ) throws {
        series.endTime = endTime
        series.sleepQuality = sleepQuality
        if let graphData = graph {
            if let _ = try fetchCacheDTO(for: series.id) {
                try deleteCache(for: series.id, forced: true)
            }
            let duration = series.endTime != nil ? series.startTime.distance(to: series.endTime!) : 0
            let cache = CacheDTO(
                bitmap: graphData,
                maxHR: Float(maxHR ?? 0),
                minHR: Float(minHR ?? 0),
                maxHRScaled: Float(maxHRScaled ?? 0),
                minHRScaled: Float(minHRScaled ?? 0),
                duration: Float(duration),
                awake: Float(statistic?.value(for: .awake) ?? 0) ,
                rem: Float(statistic?.value(for: .rem) ?? 0),
                lSeep: Float(statistic?.value(for: .lightSleep) ?? 0),
                dSleep: Float(statistic?.value(for: .deepSleep) ?? 0),
                seriesId: series.id
            )
            try insertCache(cache: cache)
        }
        try modelContext.save()
    }
    
    private func deleteSeries(_ series: Series, forced: Bool) throws {
        modelContext.delete(series)
        if forced {
            try modelContext.save()
        }
    }
    
    private func fetchSeries(seriesId: UUID) throws -> Series? {
        var descriptor = FetchDescriptor<Series>(predicate: #Predicate { $0.id == seriesId })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }
    
    private func fetchAllSeries(order: SortOrder) throws -> [Series] {
        let fetchDescriptor = FetchDescriptor<Series>(sortBy: [SortDescriptor(\.startTime, order: order)])
        return try modelContext.fetch(fetchDescriptor)
    }
    
    // --- Measurement ---
    
    func insertMeasurement(measurement: MeasurementDTO) async throws {
        let measurement = Measurement(measurement: measurement)
        try insertMeasurement(measurement)
    }
    
    func insertMeasurement(dataBundle: DataBundle, seriesId: UUID) async throws {
        if let series = try fetchSeries(seriesId: seriesId) {
            let measurement = Measurement(dataBundle: dataBundle, seriesId: series.id)
            try insertMeasurement(measurement)
        }
    }
    
    func deleteMeasurements(for seriesId: UUID, forced: Bool) throws {
        try modelContext.delete(model: Measurement.self, where: #Predicate { $0.seriesId == seriesId })
        if forced {
            try modelContext.save()
        }
    }
    
    func fetchAllMeasurementDTO(for seriesId: UUID) throws -> [MeasurementDTO] {
        let descriptor = FetchDescriptor<Measurement>(predicate: #Predicate { $0.seriesId == seriesId })
        return try modelContext.fetch(descriptor).map{ $0.toDTO() }
    }
    
    private func insertMeasurement(_ measurement: Measurement) throws {
        modelContext.insert(measurement)
        try modelContext.save()
    }
    
    // --- Cache ---
    func insertCache(cache: CacheDTO) throws {
        let cache = Cache(cacheDTO: cache)
        modelContext.insert(cache)
        try modelContext.save()
    }
    
    func deleteCache(for seriesId: UUID, forced: Bool) throws {
        try modelContext.delete(model: Cache.self, where: #Predicate { $0.seriesId == seriesId })
        if forced {
            try modelContext.save()
        }
    }
    
    func fetchCacheDTO(for seriesId: UUID) throws -> CacheDTO? {
        let fetchDescriptor = FetchDescriptor<Cache>(predicate: #Predicate { $0.seriesId == seriesId })
        let cache = try modelContext.fetch(fetchDescriptor).first
        
        guard let cache else { return nil }
        
        return cache.toDTO()
    }
    
    // --- CacheHypnogram ---
    
    func insertCacheHypnogram(hypnogram: CacheHypnogramDTO) throws {
        let hypnogram = CacheHypnogram(cacheHypnogram: hypnogram)
        try insertCacheHypnogram(hypnogram)
    }
    
    func deleteCacheHypnograms(for seriesId: UUID, forced: Bool) throws {
        try modelContext.delete(model: CacheHypnogram.self, where: #Predicate { $0.seriesId == seriesId })
        if forced {
            try modelContext.save()
        }
    }
    
    func fetchHypnogramsDTO(for seriesId: UUID) throws -> [CacheHypnogramDTO] {
        let fetchDescriptor = FetchDescriptor<CacheHypnogram>(predicate: #Predicate { $0.seriesId == seriesId })
        return try modelContext.fetch(fetchDescriptor).map { $0.toDTO() }
    }
    
    func fetchAllHypnogramDTO(for seriesId: UUID) throws -> [CacheHypnogramDTO] {
        let fetchDescriptor = FetchDescriptor<CacheHypnogram>(predicate: #Predicate { $0.seriesId == seriesId })
        return try modelContext.fetch(fetchDescriptor).map { $0.toDTO() }
    }
    
    private func insertCacheHypnogram(_ hypnogram: CacheHypnogram) throws {
        modelContext.insert(hypnogram)
        try modelContext.save()
    }
}

// MARK: - DI

extension InjectionRegistry {
    var databaseService: any DatabaseService {
        Self.instantiate(.singleton) { DatabaseServiceImpl() }
    }
}
