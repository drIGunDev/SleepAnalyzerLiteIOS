//
//  SatisfactionDialog.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 17.07.25.
//

import SwiftUI

struct ShowSatisfactionDialog: View {
    @Environment(\.dismiss) private var dismiss
    
    let cancelAction: (() -> Void)?
    let okAction: ((SeriesDTO.SleepQuality) -> Void)?
    
    @State var selectedSatisfaction: SeriesDTO.SleepQuality = .neutral
    
    public var body: some View {
        Dialog(title: "Sleep Satisfaction", cancelAction: cancelAction) {
            VStack {
                Text("Please rate your sleep, choose a smiley from the list:")
                    .font(.dialogText)
                    .lineLimit(nil)
                    .foregroundColor(.textForeground)
                ShowSatisfactionButtons()
            }
        }
    }
    
    func ShowSatisfactionButtons() -> some View {
        ZStack {
            HStack(spacing: 60){
                Button(action: { okAction!(.bad); dismiss() } ) {
                    Text(SeriesDTO.SleepQuality.bad.toEmodji())
                        .font(.largeTitle)
                    
                }
                Button(action: { okAction!(.neutral); dismiss() }) {
                    Text(SeriesDTO.SleepQuality.neutral.toEmodji())
                        .font(.largeTitle)
                    
                }
                Button(action: { okAction!(.good); dismiss() }) {
                    Text(SeriesDTO.SleepQuality.good.toEmodji())
                        .font(.largeTitle)
                    
                }
            }
            .padding([.bottom, .top], 10)
        }
    }
}

struct SatisfactionDialogTest: View {
    @State private var isPresented = false
    @State private var selected: SeriesDTO.SleepQuality = .neutral
    var body: some View {
        VStack {
            Button("Show dialog") {
                isPresented.toggle()
            }
            Text("Selected: \(selected.toEmodji())")
        }
        .popup(isPresented: $isPresented,
               dialog: ShowSatisfactionDialog(cancelAction: { isPresented.toggle() },
                                              okAction: { isPresented.toggle(); selected = $0 }))
    }
}

struct ShowSatisfactionDialog_Previews: PreviewProvider {
    static var previews: some View {
        SatisfactionDialogTest()
            .preferredColorScheme(.dark)
    }
}
