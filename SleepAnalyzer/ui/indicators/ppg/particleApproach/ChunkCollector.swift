//
//  ChunkCollector.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 01.10.25.
//

import Foundation
import Combine
import SwiftInjectLite

protocol ChunkCollector: Actor {
    typealias Frame = [Double]
    
    var frameChannel: any Publisher<ChunkCollector.Frame, Never> { get }
    
    func add(chunk: PPGArray) async
    func consumingDone() async
}

private actor ChunkCollectorImpl: ChunkCollector {
    let frameChannel: any Publisher<ChunkCollector.Frame, Never> =  PassthroughSubject()
    
    private(set) var isConsuming: Bool = false
    private var buffer: PPGArray = []
    private let collectionPeriodSec: TimeInterval
    
    init(collectionPeriodSec: TimeInterval) {
        self.collectionPeriodSec = collectionPeriodSec
    }
    
    func add(chunk: PPGArray) {
        guard !isConsuming else { return }
        
        buffer.append(contentsOf: chunk)
        
        checkAndTransfer()
    }

    func consumingDone() {
        guard isConsuming else { return }
        
        buffer.removeAll()
        isConsuming = false
    }
    
    private func checkAndTransfer() {
        guard buffer.count > 2 else { return }
        let interval = buffer.first?.timeStamp.distance(to: buffer.last?.timeStamp ?? 0) ?? 0
        guard interval > Int(collectionPeriodSec) * 1_000_000_000 else { return }
        
        isConsuming = true
        transferFrame()
    }
    
    private func transferFrame() {
        let normalizedBuffer = buffer
            .toDoubleArray()
            .substractMin()
            .lineAdjust()
            .normalize()
        
        frameChannel.asPassThroughSubject().send(normalizedBuffer)
    }
 }

private extension Array where Element == PPGPoint {
    func toDoubleArray() -> [Double] {
        map{ Double($0.sample) }
    }
}

private extension Array where Element == Double {
    func substractMin() -> [Double] {
        let min = self.min() ?? 0
        return map{ $0 - min }
    }
    
    func lineAdjust() -> [Double] {
        let a = first ?? 0
        let b = last ?? 0
        let N = Double(count)
        
        var result = [Double]()
        for (index, element) in enumerated() {
            let l = Double(index) / N
            let d = (b - a) * l + a
            let y = element - d
            result.append(y)
        }
        return result
    }
    
    func normalize() -> [Double] {
        let min = self.min() ?? 0
        let max = self.max() ?? 0
        return map { ($0 - min) / (max - min) }
    }
}

// MARK: - DI

extension InjectionRegistry {
    var chunkCollector: any ChunkCollector {
        Self.instantiate { ChunkCollectorImpl.init(collectionPeriodSec: PPGViewModelConfig.collectionPeriodSec) }
    }
}

