//
//  SleepPhase+Statistic.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 16.07.25.
//

import Foundation

struct SleepPhaseStatistic {
    private let statistic: [SleepState: Double]
    
    init(sleepPhases: [SleepPhase]) {
        self.statistic = sleepPhases.phaseDurations()
    }
    
    init(statistic: [SleepState: Double]) {
        self.statistic = statistic
    }
    
    func value(for state: SleepState) -> Double {
        guard let value = statistic[state] else { return 0 }
        
        return value
    }
    
    func percentage(for state: SleepState) -> Double {
        guard let value = statistic[state] else { return 0 }
        
        let totalDuration = self.totalDurationSeconds()
        return value / totalDuration * 100
    }
    
    func percentage() -> [SleepState: Double] {
        let totalDuration = self.totalDurationSeconds()
        
        return statistic.mapValues { $0 / totalDuration * 100 }
    }
    
    func percentage() -> [(SleepState, Double, Double)] {
        var result : [(SleepState, Double, Double)] = []
        
        result.append((.awake, statistic[.awake]!, percentage(for: .awake)))
        result.append((.lightSleep, statistic[.lightSleep]!, percentage(for: .lightSleep)))
        result.append((.deepSleep, statistic[.deepSleep]!, percentage(for: .deepSleep)))
        result.append((.rem, statistic[.rem]!, percentage(for: .rem)))
            
        return result
    }
    
    func totalDurationSeconds() -> Double {
        return statistic.values.reduce(0, +)
    }
}
