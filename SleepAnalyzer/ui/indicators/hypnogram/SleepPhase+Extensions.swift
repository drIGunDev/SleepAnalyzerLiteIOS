//
//  SleepPhase+Extensions.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 01.08.25.
//

import Foundation
import HypnogramComputation

extension Array where Element == SleepPhase {
    func phaseDurations() -> [SleepState: Double] {
        var map = [SleepState: Double]()
        SleepState.allCases.forEach { map[$0] = 0 }
        return self.reduce(into: map) { result, element in
            result[element.state]! += element.durationSeconds
        }
    }
}
