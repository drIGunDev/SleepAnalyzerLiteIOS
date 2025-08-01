//
//  Dialog.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 05.06.25.
//

import SwiftUI

struct Dialog<Content: View>: View {
    @Environment(\.dismiss) private var dismiss
    
    let title: String
    let cancelAction: (() -> Void)?
    let okAction: (() -> Void)?
    let padding: CGFloat
    let content: Content
    
    init(title: String,
         padding: CGFloat = 20,
         cancelAction: (() -> Void)? = nil,
         okAction: (() -> Void)? = nil,
         @ViewBuilder content: () -> Content) {
        self.title = title
        self.padding = padding
        self.content = content()
        self.cancelAction = cancelAction
        self.okAction = okAction
    }
    
    var body: some View {
        ZStack {
            VStack {
                Text(title)
                    .font(.dialogTitle)
                    .foregroundColor(.textForeground)
                    .padding(.top, 10)
                    .padding(.bottom, 1)
                Divider()
                content
                HStack(spacing: 40) {
                    Spacer()
                    if cancelAction != nil {
                        Button("Cancel") {
                            cancelAction?()
                            dismiss()
                        }
                        .foregroundColor(.accentColor)
                    }
                    if okAction != nil {
                        Button("OK") {
                            okAction?()
                            dismiss()
                        }
                        .foregroundColor(.accentColor)
                    }
                }
                .padding([.top, .bottom], padding)
            }
        }
        .font(.dialogText)
        .padding([.leading, .trailing], padding)
        .frame(minWidth: 250)
        .background(Color.dialogBackground)
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}

struct TestDialog: View {
    var body: some View {
        Dialog(title: "Test", cancelAction: {}, okAction: {}) {
            Text("Hello, World!")
        }
    }
}

struct TestDialog_Previews: PreviewProvider {
    static var previews: some View {
        TestDialog()
            .preferredColorScheme(.dark)
    }
}
