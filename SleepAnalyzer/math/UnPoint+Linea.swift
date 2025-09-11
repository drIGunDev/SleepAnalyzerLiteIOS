//
//  UnPoint+Linea.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 10.09.25.
//

import Foundation
import Linea

extension UnPoint {
    func toDataPoint() -> DataPoint {
        .init(x: Double(self.x), y: Double(self.y))
    }
}

extension Array where Element == UnPoint {
    func mapToDataPoints() -> [DataPoint] {
        self.map{ $0.toDataPoint() }
    }
}
