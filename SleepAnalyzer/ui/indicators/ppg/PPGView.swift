//
//  PPGView.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 24.09.25.
//

import SwiftUI
import SwiftInjectLite

struct PPGView: View {
    
    struct Style {
        let color: Color
        let lineWidth: CGFloat
    }

    @Binding var viewModel: any PPGViewModel
    var style = Style(color: .green, lineWidth: 2)
    
    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                
                let timelineDate = Date().timeIntervalSinceReferenceDate
                viewModel.particleFrameSystem.update(date: timelineDate)
                
                return Canvas { context, size in
                    guard viewModel.particleFrameSystem.isEnrichmentInProgress else { return }
                    
                    for frame in viewModel.particleFrameSystem.frames {
                        
                        var lastParticle: Particle? = nil
                        for (index, particle) in frame.particles.enumerated() {
                            
                            context.opacity = 1 - (timelineDate - particle.creationDate) * PPGViewModelConfig.dimmingFactor
                            
                            let x = CGFloat(index)
                            if let lastParticle {
                                let y0 = CGFloat(1 - lastParticle.y) * size.height
                                let y1 = CGFloat(1 - particle.y) * size.height
                                let path = linePath(x0: x, y0: y0, x1: x + 1, y1: y1)
                                let stroke = StrokeStyle(lineWidth: style.lineWidth, lineCap: .butt, lineJoin: .round)
                                context.stroke(path, with: .color(style.color), style: stroke)
                            }
                            
                            lastParticle = particle
                        }
                    }
                }
            }
            .onAppear {
                viewModel.particleFrameSystem.setInterpolationInterval(interval: geo.size.width)
            }
        }
    }
    
    private func linePath(x0: CGFloat, y0: CGFloat, x1: CGFloat, y1: CGFloat) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: x0, y: y0) )
        path.addLine(to: CGPoint(x: x1, y: y1))
        return path
    }
}
