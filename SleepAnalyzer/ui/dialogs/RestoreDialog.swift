//
//  RestoreDialog.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 05.06.25.
//

import SwiftUI

public struct RestoreDialog: View {
    let cancelAction: (() -> Void)?
    let okAction: (() -> Void)?
    
    public var body: some View {
        Dialog(title: "Restore", cancelAction: cancelAction, okAction: okAction) {
            VStack {
                Text("Some measurements need to be restored. Continue?")
                    .font(.dialogText)
                    .lineLimit(nil)
            }
        }
    }
}

struct RestoreDialogTest: View {
    @State private var isPresented = false
    var body: some View {
        VStack {
            Text("Hello, World!")
            Button("Show dialog") {
                isPresented.toggle()
            }
        }
        .popup(isPresented: $isPresented,
               dialog: RestoreDialog(cancelAction: { isPresented.toggle() },
                                     okAction: { isPresented.toggle() }))
    }
}

struct RestoreDialog_Previews: PreviewProvider {
    static var previews: some View {
        RestoreDialogTest()
            .preferredColorScheme(.dark)
    }
}
