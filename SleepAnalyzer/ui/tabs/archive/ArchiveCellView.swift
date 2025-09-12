//
//  ArchiveCellView.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 18.07.25.
//

import SwiftUI
import SwiftInjectLite
import Linea

struct ArchiveCellView: View {
    
    @State private var cellViewModel = InjectionRegistry.inject(\.archiveCellViewModel)
    
    enum GraphIds: Int { case hr, acc, gyro }
    @State private var graph: [GraphIds : LinearSeries] = [:]
    
    init(series: SeriesDTO) {
        cellViewModel.series = series
    }
    
    var body: some View {
        VStack (alignment: .leading) {
            ShowTitle()
            ShowGraph()
            ShowDescription()
            ShowHypnographStatistic()
        }
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.dialogBackground))
        .task(id: cellViewModel.refreshGraphId) {
            guard cellViewModel.image == nil else { return }
            
            let points = cellViewModel.series?.measurements
            guard let points else { return }
            guard !points.isEmpty else { return }
            
            updateGraph(points: points)
        }
        .onAppear(perform: cellViewModel.enrichSeries)
    }
}

extension ArchiveCellView {
    
    func updateGraph(points: [MeasurementDTO]) {
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

extension ArchiveCellView {
    
    func ShowTitle() -> some View {
        if let series = cellViewModel.series {
            var quality = SeriesDTO.SleepQuality.neutral
            if let qualityValue = series.sleepQuality {
                quality = SeriesDTO.SleepQuality.from(value: qualityValue)
            }
            return AnyView(
                Text("\(series.startTime.format("yyyy.MM.dd HH:mm")) \(quality.toEmodji())")
                    .font(.headline)
                    .foregroundColor(.textForeground)
                    .padding(.top, 15)
                    .padding(.leading, 20)
            )
        }
        else {
            return AnyView(EmptyView())
        }
    }
}

extension ArchiveCellView {
    
    func ShowDescription() -> some View {
        if let cache = cellViewModel.series?.cache  {
            return AnyView(
                VStack(alignment: .center) {
                    Text("minHR: \(Double(cache.minHRScaled).format("%0.f")) maxHR: \(Double(cache.maxHRScaled).format("%0.f")) (\(Double(cache.duration).toDuration()))")
                        .font(.caption)
                        .foregroundColor(.textForeground)
                        .padding(.leading, 20)
                }.frame(maxWidth: .infinity)
            )
        }
        else {
            return AnyView(EmptyView())
        }
    }
}

extension ArchiveCellView {
    
    func ShowGraph() -> some View {
        if let image = cellViewModel.image {
            return AnyView(
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .id(cellViewModel.refreshImageId)
                    .padding(.trailing, 10)
            )
        }
        
        guard let measurements = cellViewModel.series?.measurements,
              !measurements.isEmpty else {
            return AnyView(
                Color.clear
                    .frame(height: 200)
            )
        }
        
        return AnyView(
            LinearGraph(
                series: graph,
                xAxis: XAxis(
                    autoRange: .none,
                    tickProvider: FixedCountTickProvider(),
                    formatter: AnyAxisFormatter.init {
                        $0.toGraphXLabel(startTime: cellViewModel.series!.startTime, fontSize: 11)
                    },
                ),
                yAxes: YAxes<GraphIds>
                    .bind(
                        axis: YAxis(
                            autoRange: .none,
                            tickProvider: FixedCountTickProvider(),
                            formatter: AnyAxisFormatter.init {
                                $0.toGraphYLabel(fontSize: 11)
                            }
                        ),
                        to: [.hr]
                    )
                #if SA_DEBUG
                    .bind(axis: YAxis(gridEnabled: false),to: [.acc])
                    .bind(axis: YAxis(gridEnabled: false), to: [.gyro])
                #endif
                ,
                style: .init(
                    gridOpacity: 0.9,
                    cornerRadius: 0,
                    background: Color.clear,
                    xTickTarget: 3,
                    yTickTarget: 4
                ),
                panMode: .none,
                zoomMode: .none
            )
            .frame(height: 200)
            .padding([.leading, .trailing, .bottom], 20)
        )
    }
}

extension ArchiveCellView {
    
    func ShowHypnographStatistic() -> some View {
        if let statistic = cellViewModel.sleepStatistic {
            return AnyView(
                VStack(alignment: .center){
                    SleepPhaseStatisticView(
                        sleepPhaseStatistics: statistic)
                    .id(cellViewModel.refreshImageId)
                    .padding(.top, 5)
                    .padding(.bottom, 20)
                }.frame(maxWidth: .infinity)
            )
        }
        else {
            return AnyView(EmptyView())
        }
    }
}
