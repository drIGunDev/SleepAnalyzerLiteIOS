//
//  GraphViewModel+rescale.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 22.07.25.
//

import Foundation

extension GraphViewModel {
    
    func rescale() {
        let rescaleParams = AppSettings.shared.toRescaleParams()
        switch rescaleParams {
        case .autoscale: setAutoScaleX(forKey: .heartRate)
        case .scale(min: let min, max: let max):
            if let minHR = min, let maxHR = max {
                scaleX(forKey: .heartRate, minValue: minHR, maxValue: maxHR)
            }
        }
    }
}
