//
//  Series.swift
//  SleepAnalyzer
//
//  Created by Dolores(chatGPT) on 28.04.25.
//

import Foundation
import SwiftData

struct SeriesDTO: Sendable, Equatable, Hashable {
    
    enum SleepQuality: Int {
        case bad
        case neutral
        case good
        
        func toEmodji() -> String {
            switch self {
            case .bad:
                return "☹️"
            case .neutral:
                return "😐"
            case .good:
                return "😇"
            }
        }
        
        static func from(value: Int) -> SleepQuality {
            SleepQuality(rawValue: value) ?? .neutral
        }
    }
    
    private(set) var id: UUID = UUID()
    let startTime: Date
    var endTime: Date?
    var sleepQuality: Int?
    var measurements: [MeasurementDTO] = []
    var cache: CacheDTO?
    var cacheHypnograms: [CacheHypnogramDTO] = []
    
    static func from(series: Series) -> SeriesDTO {
        return SeriesDTO(
            id: series.id,
            startTime: series.startTime,
            endTime: series.endTime,
            sleepQuality: series.sleepQuality,
            measurements: []
        )
    }
    
    static func from(series: Series,
                     measuremtns: [MeasurementDTO] = [],
                     cache: CacheDTO? = nil,
                     cacheHypnograms: [CacheHypnogramDTO] = []) -> SeriesDTO {
        return SeriesDTO(
            id: series.id,
            startTime: series.startTime,
            endTime: series.endTime,
            sleepQuality: series.sleepQuality,
            measurements: measuremtns,
            cache: cache,
            cacheHypnograms: cacheHypnograms
        )
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: SeriesDTO, rhs: SeriesDTO) -> Bool {
        return lhs.id == rhs.id && lhs.measurements.count == rhs.measurements.count 
    }
}

@Model
final class Series {
    @Attribute(.unique) var id: UUID
    var startTime: Date
    var endTime: Date?
    var sleepQuality: Int?

    init(id: UUID = UUID(),
         startTime: Date,
         endTime: Date? = nil,
         sleepQuality: Int? = nil) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.sleepQuality = sleepQuality
    }
    
    init(series: SeriesDTO) {
        self.id = series.id
        self.startTime = series.startTime
        self.endTime = series.endTime
        self.sleepQuality = series.sleepQuality
    }
}

extension Series {
    func toDTO() -> SeriesDTO {
        .from(series: self)
    }
}
