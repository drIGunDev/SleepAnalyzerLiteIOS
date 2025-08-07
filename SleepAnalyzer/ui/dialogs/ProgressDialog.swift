//
//  ProgressAlert.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 03.06.25.
//

import SwiftUI

struct ProgressDialog: View {
    var title: String
    @Binding var message: String?
    @Binding var progress: Double
    let cancelAction: (() -> Void)?
    
    var body: some View {
        Dialog(title: title, cancelAction: cancelAction) {
            VStack (alignment: .leading) {
                Text(message ?? "")
                    .font(.dialogText)
                    .lineLimit(1)
                ProgressView(value: progress)
            }
            .padding(.bottom, 20)
        }
    }
}

struct ProgressAlertModifierTestContentView: View {
    @State private var displayProgressDialog = false
    @State private var displayScaleDialog = false
    @State private var progress: Double = 0
    @State private var message: String? = nil

    @State private var scaleDialogParams: ScaleDialogParams = .init()
    
    let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack{
            Text("Hello, World!")
            Spacer()
            Button("Show scale dialog") {
                progress = 0
                displayScaleDialog.toggle()
            }
            Button("Start popup") {
                progress = 0
                displayProgressDialog.toggle()
            }
        }
        .popup(isPresented: $displayScaleDialog,
               dialog: ScaleDialog(scaleDialogParams: $scaleDialogParams,
                                   cancelAction: { displayScaleDialog.toggle() },
                                   okAction: { displayProgressDialog = true; displayScaleDialog.toggle() }),
               horizontalPadding: UIConfig.popupHorizontalPadding)
        .popup(isPresented: $displayProgressDialog,
               dialog: ProgressDialog(title: "Scaling",
                                      message: $message,
                                      progress: $progress,
                                      cancelAction: { progress = 0; displayProgressDialog.toggle() }),
               horizontalPadding: UIConfig.popupHorizontalPadding)
        .onReceive(timer) { _ in
            if displayProgressDialog {
                progress += 0.1
                message = "Scalling: \(Int(progress * 100))%"
                if progress >= 1 {
                    displayProgressDialog.toggle()
                }
            }
        }
    }
}

struct ProgressDialog_Prviews: PreviewProvider {
    static var previews: some View {
        ProgressDialog(title: "Progress",
                       message: .constant("Wait of ..."),
                       progress: .constant(0.5),
                       cancelAction: { })
        .preferredColorScheme(.dark)
    }
}

struct ProgressAlert_Preview: PreviewProvider {
    static var previews: some View {
        ProgressAlertModifierTestContentView()
            .preferredColorScheme(.dark)
    }
}
