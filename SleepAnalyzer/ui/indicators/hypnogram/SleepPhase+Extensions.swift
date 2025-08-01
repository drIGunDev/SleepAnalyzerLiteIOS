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

extension SleepPhaseAd {
    func toSleepPhase() -> SleepPhase {
        SleepPhase(state: state.toSleepState(), durationSeconds: durationSeconds)
    }
}

extension Array where Element == SleepPhaseAd {
    func mapToSleepPhases() -> [SleepPhase] {
        map { $0.toSleepPhase() }
    }
}

extension SleepPhase {
    func toSleepPhaseAd() -> SleepPhaseAd {
        SleepPhaseAd(state: state.toSleepStateAd(), durationSeconds: durationSeconds)
    }
}
