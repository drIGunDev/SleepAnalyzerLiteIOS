//
//  PPGGraphView.swift
//  SleepAnalyzer
//
//  Created by Claude(Anthropic) on 12.06.25.
//

import SwiftUI

struct PPGGraphView: View {
    
    @Binding var viewModel: any PPGGraphViewModel
    
    let stepFactor: CGFloat = 0.8
    var curveColor: Color = .blue
    var topColorGradient: Color = .blue.opacity(0.7)
    var bottomColorGradient: Color = .blue.opacity(0.0)
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                createPath(geometry, isFilled: false)
                    .stroke(
                        curveColor,
                        lineWidth: 1
                    )
                
                createPath(geometry, isFilled: true)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [bottomColorGradient, topColorGradient]),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
            }
        }
    }
    
    // PPG waveform
    func createPath(_ geometry: GeometryProxy, isFilled: Bool) -> Path {
        Path { path in
            viewModel.maxPPGDataBufferSize = Int(geometry.size.width / stepFactor)
            
            guard !viewModel.ppgData.isEmpty else { return }
            
            let ppgData = viewModel.ppgData
            
            let height = geometry.size.height
            
            let firstPoint = ppgData[0]
            
            if isFilled {
                path.move(to: CGPoint(x: 0, y: height))
                path.addLine(to: CGPoint(x: 0, y: (1.0 - firstPoint) * height ))
            }
            else {
                path.move(to: CGPoint(x: 0, y: (1.0 - firstPoint) * height ))
            }
            
            // Add points for the waveform
            for i in 1..<ppgData.count {
                let x = stepFactor * CGFloat(i)
                let y = (1.0 - ppgData[i]) * height
                path.addLine(to: CGPoint(x: x, y: y))
                if isFilled && i == ppgData.count - 1 {
                    path.addLine(to: CGPoint(x: x, y: height))
                    path.closeSubpath()
                }
            }
        }
    }
}
