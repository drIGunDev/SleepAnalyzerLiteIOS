//
//  ArchiveCellView.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 18.07.25.
//

import SwiftUI
import SwiftInjectLite

struct ArchiveCellView: View {
    
    @State private var graphViewModel = InjectionRegistry.inject(\.graphViewModel)
    @State private var cellViewModel = InjectionRegistry.inject(\.archiveCellViewModel)
    
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
            
#if SA_DEBUG
            graphViewModel.setPoints(forKey: .gyro, points: points.map(\.gyro), isAxisLabel: false, color: .gyro, fillColor: nil, forcedSetCurrentSlot: false)
            graphViewModel.setPoints(forKey: .acc, points: points.map(\.acc), isAxisLabel: false, color: .acc, fillColor: nil, forcedSetCurrentSlot: false)
#endif
            graphViewModel.setPoints(forKey: .heartRate, points: points.map(\.heartRate), isAxisLabel: true, color: .heartRate, fillColor: nil, forcedSetCurrentSlot: false)
        }
        .onAppear(perform: cellViewModel.enrichSeries)
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
            return AnyView( Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .id(cellViewModel.refreshImageId)
                .padding(.trailing, 10)
            )
        }
        else {
            return AnyView(
                GraphView(
                    viewModel: $graphViewModel,
                    configuration: GraphView.Configuration(
                        xGridCount: 3,
                        yGridCount: 4,
                        xGridAxisCount: 3,
                        yGridAxisCount: 4,
                        xGap: 35,
                        yGap: 30
                    ),
                    xLabelProvider: { $0.toGraphXLabel(startTime: cellViewModel.series!.startTime, fontSize: 11) },
                    yLabelProvider: { $0.toGraphYLabel(fontSize: 11) }
                )
                .allowsHitTesting(false)
                .frame(height: 200)
                .id(graphViewModel.invalidatedId)
                .padding(.trailing, 10)
            )
        }
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
