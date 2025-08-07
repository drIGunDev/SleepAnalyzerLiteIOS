//
//  UnPoint+HCBridge.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 02.08.25.
//

import Foundation
import HypnogramComputation

extension HCPoint {
    func toUnPoint() -> UnPoint {
        UnPoint(x: x, y: y)
    }
}

extension UnPoint {
    func toHCPoint() -> HCPoint {
        HCPoint(x: x, y: y)
    }
}

extension Array where Element == UnPoint {
    
    func mapToHCPoints() -> [HCPoint] {
        map { $0.toHCPoint() }
    }
}

extension Array where Element == HCPoint {
    
    func mapToUnPoints() -> [UnPoint] {
        map { $0.toUnPoint() }
    }
}
