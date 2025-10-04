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
        struct Grid {
            let nx: Int
            let ny: Int
            let color: Color
            let lineWidth: CGFloat
        }
        let color: Color
        let lineWidth: CGFloat
        var grid: Grid = .init(nx: 7, ny: 4, color: .green.opacity(0.4), lineWidth: 0.5)
    }

    @Binding var viewModel: any PPGViewModel
    var style = Style(color: .green, lineWidth: 2)
    
    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                
                let timelineDate = Date().timeIntervalSinceReferenceDate
                viewModel.particleFrames.update(date: timelineDate)
                
                return Canvas { context, size in
                    drawGrid(context: context, size: size)
                    
                    guard viewModel.particleFrames.isEnrichmentInProgress else { return }
                    
                    for frame in viewModel.particleFrames.frames {
                        
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
                viewModel.particleFrames.setInterpolationInterval(interval: geo.size.width)
            }
        }
    }
    
    private func createLinePath(
        x0: CGFloat,
        y0: CGFloat,
        x1: CGFloat,
        y1: CGFloat
    ) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: x0, y: y0) )
        path.addLine(to: CGPoint(x: x1, y: y1))
        return path
    }

    private func drawLines(
        index: Int,
        context: inout GraphicsContext,
        size: CGSize,
        lastParticle: Particle?,
        particle: Particle
    ) {
        guard let lastParticle else { return }
        
        let stroke = StrokeStyle(lineWidth: style.lineWidth, lineCap: .butt, lineJoin: .round)

        let x = CGFloat(index)
        let y0 = CGFloat(1 - lastParticle.y) * size.height
        let y1 = CGFloat(1 - particle.y) * size.height
        let path = createLinePath(x0: x, y0: y0, x1: x + 1, y1: y1)
        
        context.stroke(path, with: .color(style.color), style: stroke)
    }
    
    private func drawGrid(context: GraphicsContext, size: CGSize) {
        
        func drawLine(_ context: GraphicsContext, _ point0: CGPoint, _ point1: CGPoint) {
            var path = Path()
            path.move(to: point0)
            path.addLine(to: point1)
            context.stroke(path, with: .color(style.grid.color), style: .init(lineWidth: style.grid.lineWidth))
        }
        
        let NX = style.grid.nx
        let NY = style.grid.ny
        let dx = size.width / CGFloat(NX - 1)
        let dy = size.height / CGFloat(NY - 1)
        for i in 1..<NX - 1 {
            let x = CGFloat(i) * dx
            drawLine(context, CGPoint(x: x, y: 0), CGPoint(x: x, y: size.height))
        }
        
        for i in 1..<NY - 1 {
            let y = CGFloat(i) * dy
            drawLine(context, CGPoint(x: 0, y: y), CGPoint(x: size.width, y: y))
        }
        
        var rect = Path()
        rect.addRect(CGRect(origin: .zero, size: size))
        context.stroke(rect, with: .color(style.grid.color), lineWidth: style.grid.lineWidth)
    }
}
