//
//  PopupModifier.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 05.06.25.
//

import SwiftUI

extension View {
    func popup<Dialog: View> (isPresented: Binding<Bool>, dialog: Dialog, horizontalPadding: CGFloat = 20) -> some View {
        modifier(PopupModifier(isPresented: isPresented, dialog: dialog, horizontalPadding: horizontalPadding))
    }
}

private struct PopupModifier<Dialog: View>: ViewModifier {
    @Binding var isPresented: Bool
    let dialog: Dialog
    let horizontalPadding: CGFloat
    
    @State private var isDialogVisible = false
    
    func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: $isPresented) {
                ZStack {
                    Color.black.opacity(0.5).ignoresSafeArea(edges: .all)
                    if isDialogVisible {
                        dialog
                            .transition(.opacity)
                            .padding(.horizontal, horizontalPadding)
                    }
                    else {
                        ZStack{}.presentationBackground(.clear)
                    }
                }
            }
            .transaction { transaction in transaction.disablesAnimations = true }
            .animation(.linear(duration: 0.2), value: isPresented)
            .onChange(of: isPresented) { _, newValue in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring) {
                        isDialogVisible = newValue
                    }
                }
            }
    }
}
