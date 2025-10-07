//
//  BatteryIndicatorView.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 26.05.25.
//

import SwiftUI

struct BatteryIndicatorView: View {
    
    let batteryLevel: UInt
    
    var body: some View {
        ZStack(alignment: .leading) {
            Rectangle()
                .frame(width: 30, height: 15)
                .foregroundColor(.gray.opacity(0.3))
                .cornerRadius(3)
            
            Rectangle()
                .frame(width: CGFloat(batteryLevel) / 100 * 30, height: 15)
                .foregroundColor(batteryColor)
                .cornerRadius(3)
        }
    }
    
    private var batteryColor: Color {
        if batteryLevel > 60 {
            return .green
        } else if batteryLevel > 20 {
            return .yellow
        } else {
            return .red
        }
    }
}
