//
//  UnPoint+Extensions.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 23.06.25.
//

import Foundation
import HypnogramComputation

extension UnPointAd {
    func toUnPoint() -> UnPoint {
        UnPoint(x: x, y: y)
    }
}

extension UnPoint {
    func toUnPointAd() -> UnPointAd {
        UnPointAd(x: x, y: y)
    }
}

extension UnPoint {
    init (_ cgPoint: CGPoint) {
        x = Double(cgPoint.x)
        y = Double(cgPoint.y)
    }
    
    func toCGPoint() -> CGPoint {
        CGPoint(x: CGFloat(x), y: CGFloat(y))
    }
}

extension Array where Element == UnPoint {
    
    func mapToUnPointAds() -> [UnPointAd] {
        map { $0.toUnPointAd() }
    }
}

extension Array where Element == UnPointAd {
    
    func mapToUnPoints() -> [UnPoint] {
        map { $0.toUnPoint() }
    }
}
