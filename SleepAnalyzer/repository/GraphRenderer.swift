//
//  GraphRenderer.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 18.07.25.
//

import SwiftUI
import SwiftInjectLite

struct GraphRenderParams {
    var width: CGFloat = UIScreen.main.bounds.width - 50
    var height: CGFloat = 200
}

enum GraphRescaleParams {
    case autoscale
    case scale(min: Double?, max: Double?)
    
    func getScale() -> (min: Double?, max: Double?) {
        if case .scale(let min, let max) = self {
            return (min, max)
        } else {
            return (nil, nil)
        }
    }
}

protocol GraphRenderer {
    @MainActor func render(
        series: SeriesDTO,
        renderParams: GraphRenderParams,
        rescaleParams: GraphRescaleParams
    ) -> Data?
}

final class GraphRendererImpl: GraphRenderer {
    
    @Inject(\.graphViewModel) private var graphViewModel
    
    @MainActor func render(
        series: SeriesDTO,
        renderParams: GraphRenderParams,
        rescaleParams: GraphRescaleParams
    ) -> Data? {
        let points = series.measurements
        guard !points.isEmpty else { return nil }
        
        graphViewModel.setPoints(forKey: .heartRate, points: points.map(\.heartRate), isAxisLabel: true, color: .heartRate, fillColor: nil, forcedSetCurrentSlot: true)
        graphViewModel.rescale()

#if SA_DEBUG
        graphViewModel.setPoints(forKey: .gyro, points: points.map(\.gyro), isAxisLabel: false, color: .gyro, fillColor: nil, forcedSetCurrentSlot: false)
        graphViewModel.setPoints(forKey: .acc, points: points.map(\.acc), isAxisLabel: false, color: .acc, fillColor: nil, forcedSetCurrentSlot: false)
#endif
        let renderer = ImageRenderer(
            content: GraphView(
                viewModel: Binding(get: { self.graphViewModel }, set: {_ in}),
                configuration: GraphView.Configuration(
                    xGridCount: 3,
                    yGridCount: 4,
                    xGridAxisCount: 3,
                    yGridAxisCount: 4,
                    xGap: 35,
                    yGap: 30
                ),
                xLabelProvider: { $0.toGraphXLabel(startTime: series.startTime, fontSize: 11) },
                yLabelProvider: { $0.toGraphYLabel(fontSize: 11) }
            )
            .padding(5)
            .frame(width: renderParams.width, height: renderParams.height)
        )
        
        return renderer.uiImage?.pngData()
    }
}
