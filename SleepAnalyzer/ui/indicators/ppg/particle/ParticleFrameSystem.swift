//
//  Particless.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 01.10.25.
//

import SwiftUI
import SwiftInjectLite

protocol ParticleFrameSystem {
    typealias FrameArray = [ParticleFrame]
    
    @MainActor var frames: FrameArray { get }
    @MainActor @ObservationIgnored var isEnrichmentInProgress: Bool { get }
    
    func bind(chunkCollector: ChunkCollector)
    func unbindChunkCollector()
    
    @MainActor func setInterpolationInterval(interval: CGFloat)
    @MainActor func startFrameEnrichment()
    @MainActor func stopFrameEnrichment()
    @MainActor func update(date: TimeInterval)
}

@Observable final class ParticleFrameSystemImpl: ParticleFrameSystem {
    
    var frames: FrameArray = []
    @ObservationIgnored private(set) var isEnrichmentInProgress: Bool = false
    
    @ObservationIgnored @Inject(\.particalizer) private var particalizer
    @ObservationIgnored private var chunkCollector: ChunkCollector?
    @ObservationIgnored private var activeFrame: ParticleFrame?
    
    init() {}
    
    func bind(chunkCollector: ChunkCollector) {
        self.chunkCollector = chunkCollector
    }
    
    func unbindChunkCollector() {
        self.chunkCollector = nil
    }
    
    func setInterpolationInterval(interval: CGFloat) {
        Task {
            await particalizer.setInterpolationInterval(interval: interval)
        }
    }
    
    func startFrameEnrichment() {
        self.isEnrichmentInProgress = true
        Task {
            guard let chunkCollector else { return }
            await particalizer.startParticalizing(chunkCollector: chunkCollector)
        }
    }
    
    func stopFrameEnrichment() {
        self.isEnrichmentInProgress = false
        Task {
            await particalizer.stopParticalizing()
        }
    }
    
    func update(date: TimeInterval) {
        guard isEnrichmentInProgress else { return }
        
        Task {
            await enrichFrame()
            
            guard !frames.isEmpty else { return }
            
            frames.removeAll(where: {$0.isDead(after: date)} )
        }
    }
    
    private func enrichFrame() async {
        if let particle = await particalizer.nextParticle() {
            if let activeFrame {
                activeFrame.addParticle(particle)
            }
            else {
                activeFrame = .init(particles: [particle])
                await MainActor.run {
                    frames.append(activeFrame!)
                }
            }
        }
        else {
            await particalizer.particalizingDone()
            activeFrame = nil
        }
    }
}

// MARK: - DI

extension InjectionRegistry {
    var particleFrameSystem: any ParticleFrameSystem { Self.instantiate { ParticleFrameSystemImpl() } }
}
