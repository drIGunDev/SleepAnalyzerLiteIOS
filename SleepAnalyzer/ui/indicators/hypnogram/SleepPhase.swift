//
//  SleepPhase.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 16.07.25.
//

import Foundation

struct SleepPhase: Identifiable {
    let id: UUID = UUID()
    let state: SleepState
    let durationSeconds: Double
}
