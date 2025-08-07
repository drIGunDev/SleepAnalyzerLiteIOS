//
//  HypnogramTrackingView.swift
//  SleepAnalyzer
//
//  Created by Claude(Anthropic) on 22.05.25.
//

import SwiftUI
import SwiftInjectLite

protocol HypnogramTrackingViewModel: ObservableObject {
    var hypnogramViewModel: any HypnogramViewModel { get set }
    var startTime: Date? { get }
    
    func startTracking(startTime: Date)
    func stopTracking()
}

@Observable class HypnogramTrackingViewModelImpl: HypnogramTrackingViewModel{
    
    var hypnogramViewModel: any HypnogramViewModel
    var startTime: Date?
    
    init(hypnogramViewModel: any HypnogramViewModel) {
        self.hypnogramViewModel = hypnogramViewModel
    }
    
    func startTracking(startTime: Date) {
        self.startTime = startTime
        self.hypnogramViewModel.startTracking(startTime: startTime)
    }
    
    func stopTracking() {
        hypnogramViewModel.sleepPhases.removeAll()
        startTime = nil
    }
}

 //MARK: - DI

extension InjectionRegistry {
    var hypnogramTrackingViewModel: any HypnogramTrackingViewModel {
        Self.instantiate(.factory) { HypnogramTrackingViewModelImpl.init(hypnogramViewModel: HypnogramViewModelImpl()) }
    }
}

// MARK: - HypnogramTrackingView

struct HypnogramTrackingView<Content: View>: View {
    @Binding var trackingViewModel: any HypnogramTrackingViewModel
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        DialView(
            isActive: trackingViewModel.startTime != nil,
            constructionColor: .construction
        ) {
            CircularHypnogramView(viewModel: $trackingViewModel.hypnogramViewModel) {
                content()
            }
        }
    }
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
                    viewModel.startTracking(startTime: Date())
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
