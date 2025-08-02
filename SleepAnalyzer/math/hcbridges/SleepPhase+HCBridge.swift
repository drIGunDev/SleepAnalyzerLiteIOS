//
//  SleepPhase+HCBridge.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 02.08.25.
//

import Foundation
import HypnogramComputation

extension HCSleepPhase {
    func toSleepPhase() -> SleepPhase {
        SleepPhase(state: state.toSleepState(), durationSeconds: durationSeconds)
    }
}

extension Array where Element == HCSleepPhase {
    func mapToSleepPhases() -> [SleepPhase] {
        map { $0.toSleepPhase() }
    }
}

extension SleepPhase {
    func toHCSleepPhase() -> HCSleepPhase {
        HCSleepPhase(state: state.toHCSleepState(), durationSeconds: durationSeconds)
    }
}

