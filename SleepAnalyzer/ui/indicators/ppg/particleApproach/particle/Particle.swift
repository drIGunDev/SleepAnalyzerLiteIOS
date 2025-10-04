//
//  Particle.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 01.10.25.
//

import Foundation

struct Particle: Sendable {
    let creationDate: Double
    let y: Double
    
    init(creationDate: Double, y: Double) {
        self.creationDate = creationDate
        self.y = y
    }
    
    func isDead(after date: Double) -> Bool {
        creationDate < date - PPGViewModelConfig.collectionPeriodSec * 10
    }
}
