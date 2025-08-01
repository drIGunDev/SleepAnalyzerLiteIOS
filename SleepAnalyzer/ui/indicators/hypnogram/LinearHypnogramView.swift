//
//  LinearHypnogramView.swift
//  SleepAnalyzer
//
//  Created by Claude(Anthropic) on 07.05.25.
//

import SwiftUI
import SwiftInjectLite

struct LinearHypnogramView: View {
    let sleepPhases: [SleepPhase]
    let colorMapping = InjectionRegistry.inject(\.hypnogramColorMapping)
    
    private let horizontalLineWidth: CGFloat
    private let verticalLineWidth: CGFloat
    
    init(
        sleepPhases: [SleepPhase],
        horizontalLineWidth: CGFloat = 6,
        verticalLineWidth: CGFloat = 0.8
    ) {
        self.sleepPhases = sleepPhases
        self.horizontalLineWidth = horizontalLineWidth
        self.verticalLineWidth = verticalLineWidth
    }
    
    var body: some View {
        ZStack {
            Canvas { context, size in
                if sleepPhases.isEmpty { return }
                
                let barHeight: CGFloat = size.height
                
                let totalDuration = sleepPhases.reduce(0) { $0 + $1.durationSeconds }
                
                var currentX: CGFloat = 0
                
                var upperPoints: [CGPoint] = []
                let firstY = getYPosition(for: sleepPhases[0].state, barHeight)
                upperPoints.append(CGPoint(x: currentX, y: firstY))
                
                for (index, phase) in sleepPhases.enumerated() {
                    let width = size.width * CGFloat(phase.durationSeconds / totalDuration)
                    let y = getYPosition(for: phase.state, barHeight)
                    
                    upperPoints.append(CGPoint(x: currentX + width, y: y))
                    
                    if index < sleepPhases.count - 1 {
                        let nextPhase = sleepPhases[index + 1]
                        let nextY = getYPosition(for: nextPhase.state, barHeight)
                        upperPoints.append(CGPoint(x: currentX + width, y: nextY))
                    }
                    
                    currentX += width
                }
                
                var lowerPoints: [CGPoint] = []
                for point in upperPoints.reversed() {
                    lowerPoints.append(CGPoint(x: point.x, y: point.y + horizontalLineWidth))
                }
                
                var mainPath = Path()
                
                mainPath.addLines(upperPoints)
                mainPath.addLine(to: lowerPoints.first!)
                mainPath.addLines(lowerPoints)
                mainPath.addLine(to: upperPoints.first!)
                
                let gradient = Gradient(colors: [
                    colorMapping.map(toColorFor: .awake),
                    colorMapping.map(toColorFor: .rem),
                    colorMapping.map(toColorFor: .lightSleep),
                    colorMapping.map(toColorFor: .deepSleep),
                ])
                
                let linearGradient = GraphicsContext.Shading.linearGradient(
                    gradient,
                    startPoint: CGPoint(x: 0, y: 0),
                    endPoint: CGPoint(x: 0, y: barHeight)
                )
                
                context.fill(mainPath, with: linearGradient)
                context.stroke(mainPath, with: linearGradient, lineWidth: verticalLineWidth)
            }
        }
    }
    
    private func getYPosition(for state: SleepState, _ barHeight: CGFloat) -> CGFloat {
        let stateHeight: CGFloat = barHeight / 3
        switch state {
        case .awake:
            return 0
        case .rem:
            return stateHeight * 1 - horizontalLineWidth/2
        case .lightSleep:
            return stateHeight * 2 - horizontalLineWidth/2
        case .deepSleep:
            return stateHeight * 3 - horizontalLineWidth
        }
    }
}

struct LinearHypnogramView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .preferredColorScheme(.dark)
                .ignoresSafeArea()
            
            LinearHypnogramView(
                sleepPhases: [
                    SleepPhase(state: .awake, durationSeconds: 20 * 60),
                    SleepPhase(state: .lightSleep, durationSeconds: 45 * 60),
                    SleepPhase(state: .deepSleep, durationSeconds: 30 * 60),
                    SleepPhase(state: .lightSleep, durationSeconds: 30 * 60),
                    SleepPhase(state: .rem, durationSeconds: 35 * 60),
                    SleepPhase(state: .awake, durationSeconds: 15 * 60),
                    SleepPhase(state: .lightSleep, durationSeconds: 40 * 60),
                    SleepPhase(state: .deepSleep, durationSeconds: 60 * 60),
                    SleepPhase(state: .lightSleep, durationSeconds: 30 * 60),
                    SleepPhase(state: .rem, durationSeconds: 50 * 60),
                    SleepPhase(state: .awake, durationSeconds: 30 * 60)
                ],
            )
            .padding()
            .frame(height: 250)
            
        }
    }
}
