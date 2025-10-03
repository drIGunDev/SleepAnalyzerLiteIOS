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
                             
                            drawLines(index: index, context: &context, size: size, lastParticle: lastParticle, particle: particle)

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
    
    private func drawLines(index: Int, context: inout GraphicsContext, size: CGSize, lastParticle: Particle?, particle: Particle) {
        guard let lastParticle else { return }
        
        let stroke = StrokeStyle(lineWidth: style.lineWidth, lineCap: .butt, lineJoin: .round)

        let x = CGFloat(index)
        let y0 = CGFloat(1 - lastParticle.y) * size.height
        let y1 = CGFloat(1 - particle.y) * size.height
        let path = createLinePath(x0: x, y0: y0, x1: x + 1, y1: y1)
        
        context.stroke(path, with: .color(style.color), style: stroke)
    }
    
    private func createLinePath(x0: CGFloat, y0: CGFloat, x1: CGFloat, y1: CGFloat) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: x0, y: y0) )
        path.addLine(to: CGPoint(x: x1, y: y1))
        return path
    }
}
