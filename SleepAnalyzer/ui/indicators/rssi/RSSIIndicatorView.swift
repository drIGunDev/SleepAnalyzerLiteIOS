//
//  RSSIIndicatorView.swift
//  SleepAnalyzer
//
//  Created by Claude(Anthropic) on 26.05.25.
//

import SwiftUI

// Signal strength indicator component
struct RSSIIndicatorView: View {
    let rssi: Int // 0-4, where 4 is full strength
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(0..<4) { index in
                Rectangle()
                    .frame(width: 3, height: 3 + CGFloat(index) * 3)
                    .foregroundColor(index < calculateSignalStrength() ? .white : .gray.opacity(0.5))
                    .cornerRadius(1)
            }
        }
    }
    
    private func calculateSignalStrength() -> Int {
        // RSSI typically ranges from -30 (very strong) to -100 (very weak)
        if rssi > -30 {
            return 4
        }else if rssi > -60 {
            return 3 // Strong
        } else if rssi > -70 {
            return 2 // Medium
        } else if rssi > -85 {
            return 1 // Weak
        } else {
            return 0 // Very weak
        }
    }
}
