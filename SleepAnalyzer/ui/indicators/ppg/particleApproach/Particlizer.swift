//
//  Particlizer.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 01.10.25.
//

import Foundation
import Combine
import SwiftInjectLite

protocol Particlizer: Actor {
    func setInterpolationInterval(interval: CGFloat) async
    func start(chunkCollector: ChunkCollector) async
    func stop() async
    func nextParticle() async -> Particle?
    func frameParticalizingDone() async
}

private actor ParticlizerImpl: Particlizer {
     
    private var chunkCollector: ChunkCollector?
    
    private var interpolatedFrame: [Double] = []
    private var interpolationInterval: CGFloat?
    private var cancellable: AnyCancellable?
    
    deinit {
        cancellable?.cancel()
    }
    
    func setInterpolationInterval(interval: CGFloat) {
        self.interpolationInterval = interval
    }
    
    func start(chunkCollector: ChunkCollector) async {
        self.chunkCollector = chunkCollector
        
        cancellable = await self.chunkCollector?.frameChannel.sink { [weak self] ppgArray in
            Task {
                guard !ppgArray.isEmpty else { return }
                guard let interval = await self?.interpolationInterval else { return }
               
                await self?.interpolateFrame(frame: ppgArray, for: interval)
            }
        }
    }
    
    func stop() async {
        cancellable?.cancel()
        cancellable = nil
        chunkCollector = nil
        await frameParticalizingDone()
    }

    func nextParticle() -> Particle? {
        guard !interpolatedFrame.isEmpty else {
            return nil
        }
        
        let y = interpolatedFrame.removeFirst()
        return Particle(creationDate: Date.now.timeIntervalSinceReferenceDate, y: y)
    }
    
    func frameParticalizingDone() async {
        interpolatedFrame.removeAll()
        await chunkCollector?.consumingDone()
    }

    private func interpolateFrame(frame: ChunkCollector.Frame, for interval: CGFloat) {
        interpolatedFrame.removeAll()

        let N = frame.count
        guard N >= 2 else { return }

        let W = Int(interval.rounded(.up))
        guard W > 0 else { return }

        let d = Double(N - 1) / Double(W)

        for i in 0...W {
            let ix = d * Double(i)
            let lo = min(Int(ix), N - 1)
            let hi = min(lo + 1, N - 1)
            let frac = ix - Double(lo)
            let y = frame[lo] + (frame[hi] - frame[lo]) * frac
            interpolatedFrame.append(y)
        }
    }
}

// MARK: - DI

extension InjectionRegistry {
    var particlizer: any Particlizer { Self.instantiate { ParticlizerImpl() } }
}
