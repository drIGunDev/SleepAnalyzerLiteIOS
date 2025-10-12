//
//  HypnogramTrackingViewModel.swift
//  SleepAnalyzer
//
//  Created by Claude(Anthropic) on 22.05.25.
//

import SwiftUI
import SwiftInjectLite

protocol HypnogramTrackingViewModel: ObservableObject {
    var hypnogramViewModel: any HypnogramViewModel { get set }
    
    func startTracking(startTime: Date)
    func stopTracking()
}

@Observable private final class HypnogramTrackingViewModelImpl: HypnogramTrackingViewModel{
    
    var hypnogramViewModel: any HypnogramViewModel
    
    init(hypnogramViewModel: any HypnogramViewModel) {
        self.hypnogramViewModel = hypnogramViewModel
    }
    
    func startTracking(startTime: Date) {
        self.hypnogramViewModel.startTracking(startTime: startTime)
    }
    
    func stopTracking() {
        hypnogramViewModel.stopTracking()
        hypnogramViewModel.sleepPhases.removeAll()
    }
}

 //MARK: - DI

extension InjectionRegistry {
    var hypnogramTrackingViewModel: any HypnogramTrackingViewModel {
        get {
            let hypnogramViewModel = Self.inject(\.hypnogramViewModel)
            return Self.instantiate(.factory) { HypnogramTrackingViewModelImpl.init(hypnogramViewModel: hypnogramViewModel)}
        }
    }
}
