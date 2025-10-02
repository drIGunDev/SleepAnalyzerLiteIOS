//
//  Interpolator.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 01.10.25.
//

import Foundation
import Combine
import SwiftInjectLite

protocol Particalizer {
    func setInterpolationInterval(interval: CGFloat) async
    func startParticalizing(chunkCollector: ChunkCollector) async
    func stopParticalizing() async
    func nextParticle() async -> Particle?
    func particalizingDone() async
}

private actor ParticalizerImpl: Particalizer {
     
    private var chunkCollector: ChunkCollector?
    
    private var interpolatedFrame: [Double] = []
    private var interpolationInterval: CGFloat?
    private nonisolated(unsafe) var cancellables: Set<AnyCancellable> = []
    
    func setInterpolationInterval(interval: CGFloat) {
        self.interpolationInterval = interval
    }
    
    func startParticalizing(chunkCollector: ChunkCollector) async {
        self.chunkCollector = chunkCollector
        
        await self.chunkCollector?.frameTransmission.sink { [weak self] ppgArray in
            Task {
                guard let interval = await self?.interpolationInterval else { return }
                
                await self?.interpolateFrame(frame: ppgArray, for: interval)
            }
        }
        .store(in: &cancellables)
    }
    
    func stopParticalizing() async {
        chunkCollector = nil
        await particalizingDone()
    }

    func nextParticle() -> Particle? {
        guard !interpolatedFrame.isEmpty else {
            return nil
        }
        
        let y = interpolatedFrame.removeFirst()
        return Particle(creationDate: Date.now.timeIntervalSinceReferenceDate, y: y)
    }
    
    func particalizingDone() async {
        interpolatedFrame.removeAll()
        await chunkCollector?.consumingDone()
    }

    private func interpolateFrame(frame: ChunkCollector.Frame, for interval: CGFloat) {
        guard !frame.isEmpty else { return }
        
        let interpolationInterval = Double(interval)
        let frameCount = Double(frame.count)
        
        if interpolationInterval >= frameCount {
            interpolatedFrame.removeAll()
            let d = Int(interpolationInterval / frameCount)
            let result = frame
                .enumerated()
                .compactMap { index, element in
                    index % d == 0 ? element : nil
                }
            interpolatedFrame.append(contentsOf: result)
        }
        else {
            interpolatedFrame.removeAll()
            let N = frameCount - 1
            let W = Int(interpolationInterval.rounded(.down))
            
            for i in 0...W {
                let ix = (N - 1)/Double(W) * Double(i)
                let y = frame[Int(ix)] + (frame[Int(ix + 1)] - frame[Int(ix)]) * (ix.truncatingRemainder(dividingBy: 1))
                interpolatedFrame.append(y)
            }
        }
    }
}

// MARK: - DI

extension InjectionRegistry {
    var particalizer: any Particalizer { Self.instantiate { ParticalizerImpl() } }
}
