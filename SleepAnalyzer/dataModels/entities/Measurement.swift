//
//  Measurement.swift
//  SleepAnalyzer
//
//  Created by Dolores(chatGPT) on 28.04.25.
//

import Foundation
import SwiftData

struct MeasurementDTO: Sendable {
    
    enum MeasurementType: Int {
        case heartRate = 10
        case acc = 8
        case gyro = 2
    }

    let id: UUID
    let timestamp: Date
    let heartRate: UInt
    let acc: Double
    let gyro: Double
    let seriesId: UUID?
    
    static func from(measurement: Measurement) -> MeasurementDTO {
        .init(id: measurement.id,
              timestamp: measurement.timestamp,
              heartRate: measurement.heartRate,
              acc: measurement.acc,
              gyro: measurement.gyro,
              seriesId: measurement.seriesId)
    }
}

@Model
final class Measurement {
    @Attribute(.unique) private(set) var id: UUID
    var timestamp: Date
    var heartRate: UInt
    var acc: Double
    var gyro: Double
    
    #Index<Measurement>([\.seriesId])
    var seriesId: UUID?
    
    init(id: UUID = UUID(),
         timestamp: Date,
         heartRate: UInt,
         acc: Double,
         gyro: Double,
         seriesId: UUID) {
        self.id = id
        self.timestamp = timestamp
        self.heartRate = heartRate
        self.acc = acc
        self.gyro = gyro
        self.seriesId = seriesId
    }
    
    init(dataBundle: DataBundle, seriesId: UUID) {
        self.id = UUID()
        self.timestamp = dataBundle.timestamp
        self.heartRate = dataBundle.hr
        self.acc = dataBundle.acc
        self.gyro = dataBundle.gyro
        self.seriesId = seriesId
    }
    
    init(measurement: MeasurementDTO) {
        self.id = measurement.id
        self.timestamp = measurement.timestamp
        self.heartRate = measurement.heartRate
        self.acc = measurement.acc
        self.gyro = measurement.gyro
        self.seriesId = measurement.seriesId
    }
}

extension Measurement {
    func toDTO() -> MeasurementDTO {
        .from(measurement: self)
    }
}
