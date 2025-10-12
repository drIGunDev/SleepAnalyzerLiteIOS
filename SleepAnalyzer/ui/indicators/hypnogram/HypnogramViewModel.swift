//
//  HypnogramViewModel.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 11.10.25.
//

import SwiftUI
import SwiftInjectLite

protocol HypnogramViewModel: ObservableObject {
    var sleepPhases: [SleepPhase] { get set }
    var startTime: Date? { get set }
    
    func startTracking(startTime: Date)
    func stopTracking()
    
    func updateTracking(sleepPhases: [SleepPhase])
}

@Observable private final class HypnogramViewModelImpl: HypnogramViewModel {
    var sleepPhases: [SleepPhase]
    var startTime: Date?
    
    init(sleepPhases: [SleepPhase] = [], startTime: Date? = nil) {
        self.sleepPhases = sleepPhases
        self.startTime = startTime
    }
    
    func startTracking(startTime: Date) {
        self.startTime = startTime
    }
    
    func stopTracking() {
        self.startTime = nil
    }
    
    func updateTracking(sleepPhases: [SleepPhase]) {
        self.sleepPhases.removeAll()
        self.sleepPhases.append(contentsOf: sleepPhases)
    }
}

//MARK: - DI

extension InjectionRegistry {
   var hypnogramViewModel: any HypnogramViewModel {
       Self.instantiate(.factory) { HypnogramViewModelImpl() }
   }
}
