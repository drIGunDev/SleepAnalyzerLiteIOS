//
//  HypnogramTrackingView.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 11.10.25.
//

import SwiftUI
import SwiftInjectLite

struct HypnogramTrackingView<Content: View>: View {
    
    @Binding var trackingViewModel: any HypnogramTrackingViewModel
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        DialView(
            isActive: trackingViewModel.hypnogramViewModel.startTime != nil,
            constructionColor: .construction
        ) {
            CircularHypnogramView(viewModel: $trackingViewModel.hypnogramViewModel) {
                content()
            }
        }
    }
}

let hypnogramTestData: [SleepPhase] = [
    SleepPhase(state: .awake, durationSeconds: 60 * 60),
    SleepPhase(state: .lightSleep, durationSeconds: 45 * 60),
    SleepPhase(state: .deepSleep, durationSeconds: 90 * 60),
    SleepPhase(state: .rem, durationSeconds: 35 * 60),
    SleepPhase(state: .lightSleep, durationSeconds: 60 * 60),
    SleepPhase(state: .deepSleep, durationSeconds: 75 * 60),
    SleepPhase(state: .rem, durationSeconds: 30 * 60),
    SleepPhase(state: .lightSleep, durationSeconds: 40 * 60),
    SleepPhase(state: .awake, durationSeconds: 10 * 60)
]

private func testDurationSec(of test: [SleepPhase]) -> TimeInterval {
    .init(test.reduce(0) { $0 + $1.durationSeconds })
}

struct HypnogramTrackingViewTestContentView: View {
    
    @State private var viewModel = InjectionRegistry.inject(\.hypnogramTrackingViewModel)
    @State private var isTrackingActive = false

    var body: some View {
        VStack{
            HypnogramTrackingView(trackingViewModel: $viewModel) {
                VStack {
                    Text("hallo world")
                }
            }
            Button(isTrackingActive ? "Stop tracking" : "Start tracking") {
                if isTrackingActive {
                    viewModel.stopTracking()
                }
                else {
                    viewModel.hypnogramViewModel.sleepPhases = hypnogramTestData
                    viewModel.startTracking(startTime: .now - testDurationSec(of: hypnogramTestData))
                }
                isTrackingActive.toggle()
            }
        }
        .padding(2)
    }
}

struct HypnogramTrackingView_Previews: PreviewProvider {
    static var previews: some View {
        HypnogramTrackingViewTestContentView()
            .preferredColorScheme(.dark)
    }
}

