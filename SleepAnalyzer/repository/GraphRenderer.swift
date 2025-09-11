//
//  GraphRenderer.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 18.07.25.
//

import SwiftUI
import SwiftInjectLite
import Linea

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

struct GraphRenderParams {
    var width: CGFloat = UIScreen.main.bounds.width - 50
    var height: CGFloat = 200
}

protocol GraphRenderer {
    @MainActor func render(
        series: SeriesDTO,
        renderParams: GraphRenderParams,
        rescaleParams: GraphRescaleParams
    ) -> Data?
}

final class GraphRendererImpl: GraphRenderer {
    
    private enum GraphIds: Int { case hr, acc, gyro }
    private var graph: [GraphIds : LinearSeries] = [:]
    
    @MainActor func render(
        series: SeriesDTO,
        renderParams: GraphRenderParams,
        rescaleParams: GraphRescaleParams
    ) -> Data? {
        let points = series.measurements
        guard !points.isEmpty else { return nil }
        
        updateGraph(points: points)
        
        let renderer = ImageRenderer(
            content:
                LinearGraph(
                    series: graph,
                    xAxis: XAxis(
                        autoRange: .none,
                        tickProvider: FixedCountTickProvider(),
                        formatter: AnyAxisFormatter.init {
                            $0.toGraphXLabel(startTime: series.startTime, fontSize: 11)
                        },
                        labelColor: .white
                    ),
                    yAxes: buildYAxes(rescaleParams),
                    style: .init(
                        cornerRadius: 0,
                        background: Color.clear,
                        xTickTarget: 3,
                        yTickTarget: 4
                    ),
                    panMode: .none,
                    zoomMode: .none
                )
                .padding(10)
                .frame(width: renderParams.width, height: renderParams.height)
        )
        
        return renderer.uiImage?.pngData()
    }
}

extension GraphRendererImpl {
    
    private func updateGraph(points: [MeasurementDTO]) {
        graph[.hr] = .init(
            points: points.map(\.heartRate).mapToDataPoints(),
            style: .init(
                color: .heartRate,
                lineWidth: 1
            )
        )
#if SA_DEBUG
        graph[.acc] = .init(
            points: points.map(\.acc).mapToDataPoints(),
            style: .init(
                color: .acc,
                lineWidth: 1
            )
        )
        graph[.gyro] = .init(
            points: points.map(\.gyro).mapToDataPoints(),
            style: .init(
                color: .gyro,
                lineWidth: 1
            )
        )
#endif
    }
}

extension GraphRendererImpl {
    
    private func buildYAxes(_ rescaleParams: GraphRescaleParams) -> YAxes<GraphIds> {
        let (min, max) = rescaleParams.getScale()
        let range: AxisAutoRange
        if min == nil || max == nil {
            range = .none
        }
        else {
            range = .fixed(min: min!, max: max!)
        }
        return YAxes<GraphIds>
            .bind(
                axis: YAxis(
                    autoRange: range,
                    tickProvider: FixedCountTickProvider(),
                    formatter: AnyAxisFormatter.init {
                        $0.toGraphYLabel(fontSize: 11)
                    },
                    labelColor: .white
                ),
                to: [.hr]
            )
#if SA_DEBUG
            .bind(axis: YAxis(gridEnabled: false),to: [.acc])
            .bind(axis: YAxis(gridEnabled: false), to: [.gyro])
#endif
    }
}

// MARK: - DI

extension InjectionRegistry {
    var graphRenderer: any GraphRenderer { Self.instantiate(.factory) { GraphRendererImpl.init() } }
}
