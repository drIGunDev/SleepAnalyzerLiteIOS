//
//  SleepPhaseStatisticView.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 16.07.25.
//

import SwiftUI
import SwiftInjectLite

struct SleepPhaseStatisticView: View {
    let sleepPhaseStatistics: SleepPhaseStatistic
    let hypColorMapping = InjectionRegistry.inject(\.hypnogramColorMapping)
    
    var body: some View {
        HStack {
            ForEach(sleepPhaseStatistics.percentage(), id: \.0) { (state, durationSeconds, percentage) in
                VStack {
                    Text("\(state.rawValue)")
                    Text("\(percentage.format("%.0f"))%")
                    Text("\(durationSeconds.toDuration())")
                }
                .font(.caption2)
                .foregroundColor(hypColorMapping.map(toColorFor: state))
            }
        }
    }
}

struct SleepPhaseStatisticView_Previews: PreviewProvider {
    static let phases: [SleepPhase] = [
        .init(state: .awake, durationSeconds: 600),
        .init(state: .lightSleep, durationSeconds: 200),
        .init(state: .deepSleep, durationSeconds: 123),
        .init(state: .rem, durationSeconds: 300),
    ]
    
    static var previews: some View {
        
        ZStack(alignment: .center){
            SleepPhaseStatisticView(sleepPhaseStatistics: .init(sleepPhases: phases))
        }
        .frame(width: .infinity)
        .frame(height: 200)
    }
}
