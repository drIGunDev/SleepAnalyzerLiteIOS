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
    @MainActor func startEnrichment()
    @MainActor func stopEnrichment()
    @MainActor func update(date: TimeInterval)
}

@Observable private final class ParticleFrameSystemImpl: ParticleFrameSystem {
    
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
    
    func startEnrichment() {
        Task {
            guard let chunkCollector else { return }
            await particalizer.startParticalizing(chunkCollector: chunkCollector)
            self.isEnrichmentInProgress = true
       }
    }
    
    func stopEnrichment() {
        Task {
            await particalizer.stopParticalizing()
            self.isEnrichmentInProgress = false
        }
    }
    
    func update(date: TimeInterval) {
        Task {
            guard isEnrichmentInProgress else { return }
            
            await enrichFrame()
            
            guard !frames.isEmpty else { return }
            
            frames.removeAll(where: {$0.isDead(after: date)} )
        }
    }
    
    private func enrichFrame() async {
        guard let particle = await particalizer.nextParticle() else {
            await particalizer.particalizingDone()
            activeFrame = nil
            return
        }
        
        if let activeFrame {
            await MainActor.run { activeFrame.addParticle(particle) }
        }
        else {
            await MainActor.run {
                activeFrame = .init(particles: [particle])
                frames.append(activeFrame!)
            }
        }
    }
}

// MARK: - DI

extension InjectionRegistry {
    var particleFrameSystem: any ParticleFrameSystem { Self.instantiate { ParticleFrameSystemImpl() } }
}
