//
//  MeasurementDTO+Extensions.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 23.06.25.
//

import Foundation
import SwiftUI

extension Array where Element == MeasurementDTO {    
    func map(_ keyPath: KeyPath<Element, UInt>) -> [UnPoint]  {
        self.map { UnPoint(x: $0.timestamp.timeIntervalSince1970, y: Double($0[keyPath: keyPath])) }
    }
    
    func map(_ keyPath: KeyPath<Element, Double>) -> [UnPoint] {
        self.map { UnPoint(x: $0.timestamp.timeIntervalSince1970, y: $0[keyPath: keyPath]) }
    }
}

extension Int {
    static let heartRate = MeasurementDTO.MeasurementType.heartRate.rawValue
    static let acc = MeasurementDTO.MeasurementType.acc.rawValue
    static let gyro = MeasurementDTO.MeasurementType.gyro.rawValue
}

extension Color {
    static let heartRate = Color(#colorLiteral(red: 0.9694761634, green: 0.2640381753, blue: 0.2145400047, alpha: 1))
    static let acc = Color.green
    static let gyro = Color.blue
}
