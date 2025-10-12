//
//  CircularHypnogramView.swift
//  SleepAnalyzer
//
//  Created by Claude(Anthropic) on 06.05.25.
//

import SwiftUI
import SwiftInjectLite

struct CircularHypnogramView<Content: View>: View {
    
    @Binding var viewModel: any HypnogramViewModel

    let colorMapping = InjectionRegistry.inject(\.hypnogramColorMapping)
    var ringThickness: CGFloat = 10
    var gapBetweenRings: CGFloat = 30
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        ZStack {
            Canvas {
                context,
                size in
                guard let startTime = viewModel.startTime else { return }
                guard !viewModel.sleepPhases.isEmpty else { return }
                
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = min(size.width, size.height) / 2 - gapBetweenRings
                
                var startAngle = getStartAngleFromDate(startTime)
                
                for (index, phase) in viewModel.sleepPhases.enumerated() {
                    let sweepAngle = .pi * phase.durationSeconds / 21600
                    
                    let path = Path { p in
                        p.addArc(
                            center: center,
                            radius: radius - ringThickness / 2,
                            startAngle: Angle(radians: Double(startAngle)),
                            endAngle: Angle(radians: Double(startAngle + sweepAngle)),
                            clockwise: false
                        )
                    }
                    
                    let color: Color = colorMapping.map(toColorFor: phase.state)
                    
                    let lineCap: CGLineCap
                    if index == 0 || index == viewModel.sleepPhases.count - 1 {
                        lineCap = .round
                    }
                    else {
                        lineCap = .butt
                    }
                    
                    context.stroke(
                        path,
                        with: .color(color),
                        style: StrokeStyle(lineWidth: ringThickness, lineCap: lineCap)
                    )
                    
                    startAngle += sweepAngle
                }
            }
            
            content()
        }
    }
    
    private func getStartAngleFromDate(_ date: Date) -> CGFloat {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)  % 12
        let minute = calendar.component(.minute, from: date)
        let hourInRadians = 2 * CGFloat.pi * CGFloat(hour) / 12
        let minuteInRadians = 2 * CGFloat.pi * CGFloat(minute) / (12 * 60)
        return hourInRadians + minuteInRadians - CGFloat.pi / 2
    }
}
