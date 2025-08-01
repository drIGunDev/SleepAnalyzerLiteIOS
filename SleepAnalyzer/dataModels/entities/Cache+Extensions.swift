//
//  Cache+Extensions.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 01.08.25.
//
import Foundation
import HypnogramComputation

extension SleepStateAd {
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
    func toSleepStateAd() -> SleepStateAd {
        switch self {
        case .awake: return .awake
        case .lightSleep: return .lightSleep
        case .deepSleep: return .deepSleep
        case .rem: return .rem
        }
    }
}
