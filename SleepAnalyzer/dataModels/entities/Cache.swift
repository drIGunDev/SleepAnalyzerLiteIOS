//
//  Cache.swift
//  SleepAnalyzer
//
//  Created by Dolores(chatGPT) on 28.04.25.
//

import Foundation
import SwiftData

enum SleepState: String, Codable, CaseIterable {
    case awake = "Awake"
    case lightSleep = "Light Sleep"
    case deepSleep = "Deep Sleep"
    case rem = "REM"
}

struct CacheDTO: Sendable {
    var id: UUID = UUID()
    let bitmap: Data?
    let maxHR: Float
    let minHR: Float
    let maxHRScaled: Float
    let minHRScaled: Float
    let duration: Float
    let awake: Float
    let rem: Float
    let lSeep: Float
    let dSleep: Float
    let seriesId: UUID?
    
    static func from(cache: Cache) -> CacheDTO {
        return CacheDTO (
            id: cache.id,
            bitmap: cache.bitmap,
            maxHR: cache.maxHR,
            minHR: cache.minHR,
            maxHRScaled: cache.maxHRScaled,
            minHRScaled: cache.minHRScaled,
            duration: cache.duration,
            awake: cache.awake,
            rem: cache.rem,
            lSeep: cache.lSeep,
            dSleep: cache.dSleep,
            seriesId: cache.seriesId
        )
    }
}

extension CacheDTO {
    func toSleepStatistic() -> SleepPhaseStatistic {
        let statistic: [SleepState: Double] = [
            .awake: Double(awake),
            .lightSleep: Double(lSeep),
            .deepSleep: Double(dSleep),
            .rem: Double(rem)
        ]
        return SleepPhaseStatistic(statistic: statistic)
    }
}

@Model
final class Cache {
    @Attribute(.unique) private(set) var id: UUID
    
    var bitmap: Data?
    var maxHR: Float
    var minHR: Float
    var maxHRScaled: Float
    var minHRScaled: Float
    var duration: Float
    var awake: Float
    var rem: Float
    var lSeep: Float
    var dSleep: Float

    #Index<Cache>([\.seriesId])
    var seriesId: UUID?

    init(id: UUID = UUID(),
         bitmap: Data? = nil,
         maxHR: Float,
         minHR: Float,
         maxHRScaled: Float,
         minHRScaled: Float,
         duration: Float,
         awake: Float,
         rem: Float,
         lSeep: Float,
         dSleep: Float,
         seriesId: UUID) {
        self.id = id
        self.bitmap = bitmap
        self.maxHR = maxHR
        self.minHR = minHR
        self.maxHRScaled = maxHRScaled
        self.minHRScaled = minHRScaled
        self.duration = duration
        self.awake = awake
        self.rem = rem
        self.lSeep = lSeep
        self.dSleep = dSleep
        self.seriesId = seriesId
    }
    
    init(cacheDTO: CacheDTO) {
        self.id = cacheDTO.id
        self.bitmap = cacheDTO.bitmap
        self.maxHR = cacheDTO.maxHR
        self.minHR = cacheDTO.minHR
        self.maxHRScaled = cacheDTO.maxHRScaled
        self.minHRScaled = cacheDTO.minHRScaled
        self.duration = cacheDTO.duration
        self.awake = cacheDTO.awake
        self.rem = cacheDTO.rem
        self.lSeep = cacheDTO.lSeep
        self.dSleep = cacheDTO.dSleep
        self.seriesId = cacheDTO.seriesId
    }
}

extension Cache {
    func toDTO() -> CacheDTO {
        .from(cache: self)
    }
}
