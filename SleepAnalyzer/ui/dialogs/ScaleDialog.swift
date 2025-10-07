//
//  ScaleDialog.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 05.06.25.
//

import SwiftUI

@Observable final class ScaleDialogParams {
    var minHR: String
    var maxHR: String
    var isAutoscaleOn: Bool
    
    init() {
        self.minHR = AppSettings.shared.minHR?.format("%.0f") ?? "40"
        self.maxHR = AppSettings.shared.maxHR?.format("%.0f") ?? "100"
        self.isAutoscaleOn = AppSettings.shared.autoscale
    }
    
    func updateSettings() {
        AppSettings.shared.autoscale = isAutoscaleOn
        AppSettings.shared.minHR = Double(minHR)
        AppSettings.shared.maxHR = Double(maxHR)
    }
}

struct ScaleDialog: View {
    
    @Binding var scaleDialogParams: ScaleDialogParams

    let cancelAction: (() -> Void)?
    let okAction: (() -> Void)?
    
    var body: some View {
        Dialog(title: "Scale", cancelAction: cancelAction, okAction: { scaleDialogParams.updateSettings(); okAction?() }) {
            VStack(alignment:.leading, spacing: 10) {
                Toggle(isOn: $scaleDialogParams.isAutoscaleOn) {
                    Text("Autoscale")
                }
                .toggleStyle(.switch)
                if !scaleDialogParams.isAutoscaleOn {
                    HStack {
                        Text("min HR :")
                        TextField("(BPM)", text: $scaleDialogParams.minHR)
                            .keyboardType(.decimalPad)
                    }
                    HStack {
                        Text("max HR :")
                        TextField("(BPM)", text: $scaleDialogParams.maxHR)
                            .keyboardType(.decimalPad)
                    }
                }
            }
            .font(.dialogText)
            .foregroundColor(.textForeground)
            .animation(.linear(duration: 0.15), value: scaleDialogParams.isAutoscaleOn)
        }
    }
}

struct ScaleDialog_Previews: PreviewProvider {
    
    @State static var scaleDialogParams: ScaleDialogParams = .init()
    static var previews: some View {
        ScaleDialog(scaleDialogParams: $scaleDialogParams,
                    cancelAction: {},
                    okAction: {}
        )
        .preferredColorScheme(.dark)
    }
}
