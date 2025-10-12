//
//  TestCircularHypnogram.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 11.10.25.
//

import SwiftUI
import SwiftInjectLite

private struct CircularHypnogramViewTest: View {
    
    @State var viewModel = InjectionRegistry.inject(\.hypnogramViewModel)
    
    init() {
        viewModel.sleepPhases = hypnogramTestData
        viewModel.startTime = dateFromString("2025-05-07 15:00:00", format: "yyyy-MM-dd HH:mm:ss")!
    }
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            CircularHypnogramView(
                viewModel: $viewModel
            )
            {
                Text("Сон")
                    .font(.title)
                    .fontWeight(.bold)
            }
            .frame(height: .infinity)
        }
    }
}

struct CircularHypnogramView_Previews: PreviewProvider {
    static var previews: some View {
        CircularHypnogramViewTest()
    }
}

@Observable class MockHypnogramViewModel: HypnogramViewModel {
    var sleepPhases: [SleepPhase] = []
    var startTime: Date? = Date()
    var isRunningSimulation = false
    
    private let definedSleepPhases: [SleepPhase] = hypnogramTestData
    
    func startTracking(startTime: Date) {
        self.startTime = startTime
    }
    
    func stopTracking() {
        self.startTime = nil
    }
    
    func startSimulation() {
        Task {
            isRunningSimulation = true
            Task{ @MainActor in sleepPhases.removeAll() }
            for time in stride(from: 0, to: 60 * 60 * 12, by: 60) {
                let slice = getHypnogramSlice(until: TimeInterval(time))
                Task{ @MainActor in updateTracking(sleepPhases: slice.0) }
                if slice.1 { break }
                await delay(0.1)
            }
            isRunningSimulation = false
        }
    }
    
    func updateTracking(sleepPhases: [SleepPhase]) {
        self.sleepPhases.removeAll()
        self.sleepPhases.append(contentsOf: sleepPhases)
    }
    
    private func getHypnogramSlice(until time: TimeInterval) -> ([SleepPhase], Bool) {
        var result: [SleepPhase] = []
        var breakSimulation = false
        var phaseTime: TimeInterval = 0
        for (index, phase) in definedSleepPhases.enumerated()  {
            if phaseTime + TimeInterval(phase.durationSeconds) <= time {
                phaseTime += TimeInterval(phase.durationSeconds)
                result.append(phase)
                if index == definedSleepPhases.count - 1 {
                    breakSimulation = true
                }
            }
            else {
                let particalPhase = SleepPhase(state: phase.state, durationSeconds: time - phaseTime)
                result.append(particalPhase)
                break
            }
            
        }
        return (result, breakSimulation)
    }
}

struct CircularHypnogramViewDynamicTestContentView: View {
    
    @State var viewModel: any HypnogramViewModel = MockHypnogramViewModel()
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            CircularHypnogramView(
                viewModel: $viewModel
            )
            {
                Button("Start simuation") {
                    (viewModel as! MockHypnogramViewModel).startSimulation()
                }
                .disabled((viewModel as! MockHypnogramViewModel).isRunningSimulation)
            }
        }
    }
}

private func dateFromString(_ dateString: String, format: String) -> Date? {
    let formatter = DateFormatter()
    formatter.dateFormat = format
    return formatter.date(from: dateString)
}

struct CircularHypnogramViewDynamic_Preview: PreviewProvider {
    
    static var previews: some View {
        CircularHypnogramViewDynamicTestContentView()
    }
}
