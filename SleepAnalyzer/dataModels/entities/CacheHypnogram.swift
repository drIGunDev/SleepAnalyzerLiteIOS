//
//  CacheHypnogram.swift
//  SleepAnalyzer
//
//  Created by Dolores(chatGPT) on 28.04.25.
//

import Foundation
import SwiftData

struct CacheHypnogramDTO: Sendable {
    var id: UUID = UUID()
    let sleepState: SleepState
    let startTime: Date
    let seriesId: UUID?
    
    static func from(hypnotram: CacheHypnogram) -> CacheHypnogramDTO {
        .init(id: hypnotram.id,
              sleepState: hypnotram.sleepState,
              startTime: hypnotram.startTime,
              seriesId: hypnotram.seriesId)
    }
}

@Model
final class CacheHypnogram {
    @Attribute(.unique) private(set) var id: UUID
    var sleepState: SleepState
    var startTime: Date

    #Index<CacheHypnogram>([\.seriesId])
    var seriesId: UUID?

    init(id: UUID = UUID(),
         sleepState: SleepState,
         startTime: Date,
         seriesId: UUID) {
        self.id = id
        self.sleepState = sleepState
        self.startTime = startTime
        self.seriesId = seriesId
    }
    
    init(cacheHypnogram: CacheHypnogramDTO) {
        self.id = cacheHypnogram.id
        self.sleepState = cacheHypnogram.sleepState
        self.startTime = cacheHypnogram.startTime
        self.seriesId = cacheHypnogram.seriesId
    }
}

extension CacheHypnogram {
    func toDTO() -> CacheHypnogramDTO {
        .from(hypnotram: self)
    }
}
