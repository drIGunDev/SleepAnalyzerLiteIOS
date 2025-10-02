//
//  Frame.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 01.10.25.
//

import Foundation

final class ParticleFrame: @unchecked Sendable {
    
    private(set) var particles: [Particle] = []
    
    init(particles: [Particle]) {
        self.particles = particles
    }
    
    func addParticle(_ particle: Particle) {
        particles.append(particle)
    }
    
    func isDead(after date: TimeInterval) -> Bool {
        particles.isEmpty || particles.allSatisfy { $0.isDead(after: date) }
    }
}
