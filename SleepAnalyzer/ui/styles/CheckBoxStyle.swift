//
//  CheckBoxStyle.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 23.07.25.
//

import SwiftUI

struct CheckboxToggleStyle: ToggleStyle {
    let textAlignment: TextAlignment
    let color: Color
    init(_ textAlignment: TextAlignment, _ color: Color = .accentColor) {
        self.textAlignment = textAlignment
        self.color = color
    }
    func makeBody(configuration: Configuration) -> some View {
        Button(action: {
            configuration.isOn.toggle()
        }, label: {
            switch textAlignment {
            case .leading:
                HStack {
                    configuration.label.foregroundColor(color)
                    Image(systemName: configuration.isOn ? "checkmark.square" : "square")
                }
            case .center, .trailing:
                HStack {
                    Image(systemName: configuration.isOn ? "checkmark.square" : "square")
                    configuration.label.foregroundColor(color)
                }
            }
        })
    }
}
