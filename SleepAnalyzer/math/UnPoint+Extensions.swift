//
//  UnPoint+Extensions.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 23.06.25.
//

import Foundation
import HypnogramComputation

extension UnPoint {
    init (_ cgPoint: CGPoint) {
        x = Double(cgPoint.x)
        y = Double(cgPoint.y)
    }
    
    func toCGPoint() -> CGPoint {
        CGPoint(x: CGFloat(x), y: CGFloat(y))
    }
}
