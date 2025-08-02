//
//  Cache+HCBridge.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 01.08.25.
//
import Foundation
import HypnogramComputation

extension HCSleepState {
    func toSleepState() -> SleepState {
        switch self {
        case .awake: return .awake
        case .lightSleep: return .lightSleep
        case .deepSleep: return .deepSleep
        case .rem: return .rem
        @unknown default: return .awake
        }
    }
}

extension SleepState {
    func toHCSleepState() -> HCSleepState {
        switch self {
        case .awake: return .awake
        case .lightSleep: return .lightSleep
        case .deepSleep: return .deepSleep
        case .rem: return .rem
        }
    }
}
