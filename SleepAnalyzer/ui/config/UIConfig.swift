//
//  UIConfig.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 05.06.25.
//

import Foundation
import SwiftUI

enum UIConfig {
    static let popupHorizontalPadding: CGFloat = 26
}

extension Font {
    static let dialogTitle = Font.headline
    static let dialogText = Font.subheadline
}

extension Color {
    static let disabled = Color.gray.opacity(0.5)
    static let dialogBackground = Color(#colorLiteral(red: 0.1434547901, green: 0.1629017293, blue: 0.1772339046, alpha: 1))
    static let textForeground = Color(#colorLiteral(red: 0.8835826516, green: 0.8870513439, blue: 0.9146992564, alpha: 1))
    static let mainBackground = Color(#colorLiteral(red: 0.0659404695, green: 0.07681330293, blue: 0.09275915474, alpha: 1))
    static let graphGrid = Color.gray.opacity(0.5)
    static let graphText = Color.textForeground
    static let construction = Color(#colorLiteral(red: 0.5418865085, green: 0.5418865085, blue: 0.7278710008, alpha: 1))
}
