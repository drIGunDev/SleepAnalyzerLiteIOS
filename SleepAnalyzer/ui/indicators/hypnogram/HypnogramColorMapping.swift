//
//  HypnogramColorMapping.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 16.07.25.
//

import SwiftUI
import SwiftInjectLite

enum HypnogramColorsDefault {
    static let awake = Color(#colorLiteral(red: 0.9932342172, green: 0.4519827366, blue: 0.4519827366, alpha: 1))
    static let rem = Color(#colorLiteral(red: 0.9490135312, green: 0.5495558977, blue: 1, alpha: 1))
    static let lightSleep = Color(#colorLiteral(red: 0.7097539902, green: 0.7206355929, blue: 0.9932342172, alpha: 1))
    static let deepSleep = Color(#colorLiteral(red: 0.4559624195, green: 0.4953902364, blue: 0.9932342172, alpha: 1))
}

protocol HypnogramColorMapping {
    func map(toColorFor state: SleepState) -> Color
}

final class HypnogramColorMappingImpl: HypnogramColorMapping {
    func map(toColorFor state: SleepState) -> Color {
        switch state {
        case .awake:
            return HypnogramColorsDefault.awake
        case .rem:
            return HypnogramColorsDefault.rem
        case .lightSleep:
            return HypnogramColorsDefault.lightSleep
        case .deepSleep:
            return HypnogramColorsDefault.deepSleep
        }
    }
}

// MARK: - DI

extension InjectionRegistry {
    var hypnogramColorMapping: any HypnogramColorMapping { Self.instantiate(.factory) { HypnogramColorMappingImpl.init() } }
 }
