//
//  PPGViewModel.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 01.10.25.
//

import SwiftUI
import Combine
import SwiftInjectLite

enum PPGViewModelConfig {
    static let collectionPeriodSec: TimeInterval = 3
    static let dimmingFactor: Double = 0.2
}

protocol PPGViewModel: AnyObject {
    var particleFrames: any ParticleFrameSystem { get }

    @MainActor func subscribe()
    @MainActor func unsubscribe()
}

@Observable private final class PPGViewModelImpl: PPGViewModel {

    var particleFrames = InjectionRegistry.inject(\.particleFrameSystem)
    
    @ObservationIgnored @Inject(\.sensorDataSource) private var dataSource
    @ObservationIgnored @Inject(\.chunkCollector) private var chunkCollector
    
    private var cancellables: Set<AnyCancellable> = []
    private var isSubscribedToPPG: Bool = false
    
    init() {
        self.particleFrames.bind(chunkCollector: chunkCollector)
        
        Task {
            await dataSource.ppg.sink { [weak self] ppgData in
                Task {
                    guard self?.isSubscribedToPPG == true else { return }
                    await self?.chunkCollector.add(chunk: ppgData)
                }
            }
            .store(in: &cancellables)
        }
    }
    
    @MainActor deinit {
        unsubscribe()
    }
    
    @MainActor
    func subscribe() {
        isSubscribedToPPG = true
        particleFrames.startEnrichment()
    }
    
    @MainActor
    func unsubscribe() {
        isSubscribedToPPG = false
        particleFrames.stopEnrichment()
    }
}

// MARK: - DI

extension InjectionRegistry {
    var ppgViewModel: any PPGViewModel { Self.instantiate { PPGViewModelImpl() } }
}
