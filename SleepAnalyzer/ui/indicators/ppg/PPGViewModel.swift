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
    var particleFrameSystem: ParticleFrameSystem { get }

    @MainActor func start()
    @MainActor func stop()
}

@Observable final class PPGViewModelImpl: PPGViewModel {

    var particleFrameSystem = InjectionRegistry.inject(\.particleFrameSystem)
    
    @ObservationIgnored @Inject(\.sensorDataSource) private var dataSource
    @ObservationIgnored @Inject(\.chunkCollector) private var chunkCollector
    
    
    private var cancellables: Set<AnyCancellable> = []
    private var isSubscribedToPPG: Bool = false
    
    init() {
        self.particleFrameSystem.bind(chunkCollector: chunkCollector)
        
        dataSource.ppgDataSubject.sink { [weak self] ppgData in
            Task {
                guard self?.isSubscribedToPPG == true else { return }
                await self?.chunkCollector.add(chunk: ppgData)
            }
        }
        .store(in: &cancellables)
    }
    
    @MainActor deinit {
        stop()
    }
    
    @MainActor
    func start() {
        isSubscribedToPPG = true
        particleFrameSystem.startFrameEnrichment()
    }
    
    @MainActor
    func stop() {
        isSubscribedToPPG = false
        particleFrameSystem.stopFrameEnrichment()
    }
}

// MARK: - DI

extension InjectionRegistry {
    var ppgViewModel: any PPGViewModel { Self.instantiate { PPGViewModelImpl() } }
}
