//
//  ManualConfigurationDialog.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 02.07.25.
//

import SwiftUI
import SwiftInjectLite

struct ManualConfigurationDialog: View {
    @Binding private var modelParams: any ModelConfigurationParams

    let okAction: (() -> Void)?

    init(modelParams: Binding<any ModelConfigurationParams>,
         okAction: (() -> Void)?) {
        self._modelParams = modelParams
        self.okAction = okAction
    }
    var body: some View {
        Dialog(title: "Params configuration", okAction: okAction) {
            VStack(alignment: .leading, spacing:2) {
                let textWidth: CGFloat = 180
                HStack {
                    Text("frame size HR:")
                        .frame(width: textWidth, alignment: .trailing)
                    TextField("(Int)", value: $modelParams.frameSizeHR, formatter: NumberFormatters.zerroFractionDigits)
                }
                HStack {
                    Text("frame size ACC:")
                        .frame(width: textWidth, alignment: .trailing)
                    TextField("(Int)", value: $modelParams.frameSizeACC, formatter: NumberFormatters.zerroFractionDigits)
                }
                HStack {
                    Text("quantization HR:")
                        .frame(width: textWidth, alignment: .trailing)
                    TextField("(Double)", value: $modelParams.quantizationHR, formatter: NumberFormatters.twoFractionDigits)
                }
                HStack {
                    Text("quantiyation ACC:")
                        .frame(width: textWidth, alignment: .trailing)
                    TextField("(Double)", value: $modelParams.quantizationACC, formatter: NumberFormatters.twoFractionDigits)
                }
            }
            .font(.dialogText)
            .padding(.bottom, 20)
        }
        .foregroundColor(.textForeground)
    }
}

private struct NumberFormatters {
    static var twoFractionDigits: Formatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter
    }
    
    static var zerroFractionDigits: Formatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }
}

struct ManualConfigurationDialog_Previews: PreviewProvider {
    @State static var modelParams = InjectionRegistry.inject(\.modelConfigurationParams)
    static var previews: some View {
        ManualConfigurationDialog(
            modelParams: $modelParams,
            okAction: {}
        )
        .preferredColorScheme(.dark)
    }
}
