//
//  DetailView.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 23.06.25.
//

import SwiftUI
import SwiftInjectLite
import Linea

struct DetailView: View {
    
    @State private var detailViewModel = InjectionRegistry.inject(\.detailViewModel)
    @State private var modelParams = InjectionRegistry.inject(\.modelConfigurationParams)
    
    enum GraphIds: Int {
        case hr, hrMean, hrStdDev, hrQuant,
             acc, accMean, accStdDev, accQuant,
             hypnoQuant1, hypnoQuant2,
             gyro
    }
    @State private var graph: [GraphIds : LinearSeries] = [:]
    let yAxes = YAxes<GraphIds>
#if SA_DEBUG
        .bind(
            axis: YAxis(
                autoRange: .none,
                tickProvider: FixedCountTickProvider(),
                formatter: AnyAxisFormatter.init { $0.toGraphYLabel(fontSize: 11) }
            ),
            to: [.hr, .hrMean]
        )
        .bind(axis: YAxis(gridEnabled: false),to: [.hrStdDev])
        .bind(axis: YAxis(autoRange: .fixed(min: 0, max: 1), gridEnabled: false),to: [.hrQuant])
        .bind(axis: YAxis(autoRange: .fixed(min: 0, max: 1), gridEnabled: false),to: [.acc, .accMean])
        .bind(axis: YAxis(gridEnabled: false),to: [.accStdDev])
        .bind(axis: YAxis(autoRange: .fixed(min: 0, max: 1), gridEnabled: false),to: [.accQuant])
        .bind(axis: YAxis(autoRange: .fixed(min: 0, max: 1), gridEnabled: false),to: [.hypnoQuant1, .hypnoQuant2])
        .bind(axis: YAxis(gridEnabled: false), to: [.gyro])
#else
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
#endif
    
    @State private var currentMeasurementsCount: Int = 0
    
#if SA_DEBUG
    @State private var displayHROverlay = false
    @State private var displayACCOverlay = false
    @State private var displayHypnoOverlay = false
#endif
    @State private var graphId: Int = 0
    
    @Binding private var isTabbarVisible: Bool
    @State private var showSettings = false
    @State private var sleepPhases: [SleepPhase] = []
    
    private let keyPathHR = \MeasurementDTO.heartRate
    private let keyPathACC = \MeasurementDTO.acc
    private let keyPathGYRO = \MeasurementDTO.gyro
    
    init(series: SeriesDTO,
         isTabbarVisible: Binding<Bool>) {
        self._isTabbarVisible = isTabbarVisible
        self.detailViewModel.series = series
        self.currentMeasurementsCount = series.measurements.count
    }
    
    var body: some View {
        VStack {
            ShowTitle()
#if SA_DEBUG
                .padding([.top, .bottom], 20)
#else
                .padding([.top, .bottom], 40)
#endif
            LinearHypnogramView(sleepPhases: sleepPhases)
                .padding([.leading], 5)
                .padding([.trailing], 5)
#if SA_DEBUG
                .frame(height: 80)
#else
                .frame(height: 120)
#endif
            SleepPhaseStatisticView(sleepPhaseStatistics: .init(sleepPhases: sleepPhases))
                .frame(height: 80)
                .padding([.top, .bottom], 5)
            
            LinearGraph(
                series: graph,
                xAxis: XAxis(
                    autoRange: .none,
                    tickProvider: FixedCountTickProvider(),
                    formatter: AnyAxisFormatter.init {
                        $0.toGraphXLabel(startTime: detailViewModel.series!.startTime, fontSize: 11)
                    },
                    labelColor: .white
                ),
                yAxes: yAxes,
                style: .init(
                    cornerRadius: 0,
                    background: Color.clear,
                    xTickTarget: 3,
                    yTickTarget: 4
                ),
                panMode: .x,
                zoomMode: .x
            )
            .padding(5)
            .frame(height: 200)
#if SA_DEBUG
            ShowDebugControlls()
#endif
            Spacer()
        }
        .padding(.horizontal)
        // HR
        .task(id: detailViewModel.series?.measurements.count ?? 0) {
            updateHR()
            updateHypnogram()
        }
#if SA_DEBUG
        // ACC + GYRO
        .task(id: Double(currentMeasurementsCount)) {
            updateACC()
            updateGyro()
        }
        // HR mean + rmse
        .task(id: Double(currentMeasurementsCount) + modelParams.frameSizeHR + modelParams.quantizationHR + (displayHROverlay ? 1 : 0)) {
            updateHRMean()
            updateHRRMSE()
        }
        // ACC mean + rmse
        .task(id: Double(currentMeasurementsCount) + modelParams.frameSizeACC + modelParams.quantizationACC + (displayACCOverlay ? 1 : 0)) {
            updateACCMean()
            updateACCRMSE()
        }
        // hypnogram
        .task(id: graphId + (displayHypnoOverlay ? 1 : 0)) {
            updateHypnogramOverlays()
            updateHypnogram()
        }
#endif
        .onAppear(perform: detailViewModel.enrich)
        .onAppear { withAnimation { isTabbarVisible = false } }
        .onDisappear { withAnimation { isTabbarVisible = true } }
        .popup(
            isPresented: $showSettings,
            dialog: ManualConfigurationDialog(modelParams: $modelParams, okAction: { showSettings = false })
        )
    }
    
    @ViewBuilder func ShowTitle() -> some View {
        Text("\(detailViewModel.series?.startTime.format("yyyy.MM.dd HH:mm") ?? "--:--") - \(detailViewModel.series?.endTime?.format("HH:mm") ?? "--:--")")
            .font(.headline)
            .foregroundColor(.textForeground)
            .lineLimit(1)
            .minimumScaleFactor(0.3)
    }
    
    func invalidateHypnogram() {
        self.graphId += 1
    }
    
    func updateHR() {
        graph[.hr]?.clean()
        
        let points = detailViewModel.getMeasurements()
        guard !points.isEmpty else { return }
        
        currentMeasurementsCount = points.count
        
        let hr = points.map(keyPathHR)
            .mapToDataPoints()
        graph[.hr] = .init(
            points: hr,
            style: .init(
                color: .heartRate,
                lineWidth: 1
            )
        )
        
        invalidateHypnogram()
    }
    
    func updateHypnogram() {
        let points = detailViewModel.getMeasurements()
        guard !points.isEmpty else { return }
        
        sleepPhases = detailViewModel.hypnogramComp
            .createHypnogram(from: points, modelParams: modelParams)
    }
    
#if SA_DEBUG
    func updateHRMean() {
        graph[.hrMean]?.clean()
        
        guard displayHROverlay else {
            invalidateHypnogram()
            return
        }
        
        let points = detailViewModel.getMeasurements()
        guard !points.isEmpty else { return }
        
        let hrMean = points
            .map(keyPathHR)
            .mapToHCPoints()
            .mean(frameSize: Int(modelParams.frameSizeHR))
            .mapToUnPoints()
            .mapToDataPoints()
        graph[.hrMean] = .init(
            points: hrMean,
            style: .init(
                color: Color(#colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1)),
                lineWidth: 1
            )
        )
        
        invalidateHypnogram()
    }
    
    func updateHRRMSE() {
        graph[.hrStdDev]?.clean()
        graph[.hrQuant]?.clean()
        
        guard displayHROverlay else {
            invalidateHypnogram()
            return
        }
        let points = detailViewModel.getMeasurements()
        guard !points.isEmpty else { return }
        
        let hr = points.map(keyPathHR)
        
        let hrRmse = hr
            .mapToHCPoints()
            .rmse(frameSize: Int(modelParams.frameSizeHR))
            .mapToUnPoints()
            .mapToDataPoints()
        
        graph[.hrStdDev] = .init(
            points: hrRmse,
            style: .init(
                color: Color(#colorLiteral(red: 0.9764705896, green: 0.850980401, blue: 0.5490196347, alpha: 1)),
                lineWidth: 1
            )
        )
        
        let quant = detailViewModel.hypnogramComp
            .createUniformInput(from: hr,
                                frameSize: modelParams.frameSizeHR,
                                quantization: modelParams.quantizationHR,
                                cutoff: modelParams.hrHiPassCutoff)
            .mapToDataPoints()
        
        graph[.hrQuant] = .init(
            points: quant,
            style: .init(
                color: Color(#colorLiteral(red: 0.8549019694, green: 0.250980407, blue: 0.4784313738, alpha: 1)),
                lineWidth: 1,
                fill: Color(#colorLiteral(red: 0.7647058964, green: 0.3967176876, blue: 0.393351266, alpha: 0.5))
            )
        )
        
        invalidateHypnogram()
    }
    
    func updateACC() {
        graph[.acc]?.clean()
        
        let points = detailViewModel.getMeasurements()
        guard !points.isEmpty else { return }
        
        let acc = points.map(keyPathACC)
            .mapToHCPoints()
            .normalize()
            .mapToUnPoints()
            .mapToDataPoints()
        
        graph[.acc] = .init(
            points: acc,
            style: .init(
                color: .green,
                lineWidth: 1,
            )
        )
        
        invalidateHypnogram()
    }
    
    func updateACCMean() {
        graph[.accMean]?.clean()
        
        guard displayACCOverlay else {
            invalidateHypnogram()
            return
        }
        let points = detailViewModel.getMeasurements()
        guard !points.isEmpty else { return }
        
        let accMean = points
            .map(keyPathACC)
            .mapToHCPoints()
            .mean(frameSize: Int(modelParams.frameSizeACC))
            .normalize()
            .mapToUnPoints()
            .mapToDataPoints()
        
        graph[.accMean] = .init(
            points: accMean,
            style: .init(
                color: Color(#colorLiteral(red: 0.5843137503, green: 0.8235294223, blue: 0.4196078479, alpha: 1)),
                lineWidth: 1,
            )
        )
        
        invalidateHypnogram()
    }
    
    func updateACCRMSE() {
        graph[.accStdDev]?.clean()
        graph[.accQuant]?.clean()
        
        guard displayACCOverlay else {
            invalidateHypnogram()
            return
        }
        let points = detailViewModel.getMeasurements()
        guard !points.isEmpty else { return }
        
        let acc = points.map(keyPathACC)
        let accRmse = acc
            .mapToHCPoints()
            .rmse(frameSize: Int(modelParams.frameSizeACC))
            .mapToUnPoints()
            .mapToDataPoints()
        
        graph[.accStdDev] = .init(
            points: accRmse,
            style: .init(
                color: .blue,
                lineWidth: 1,
            )
        )
        
        let quant = detailViewModel.hypnogramComp
            .createUniformInput(from: acc,
                                frameSize: modelParams.frameSizeACC,
                                quantization: modelParams.quantizationACC,
                                cutoff: modelParams.accHiPassCutoff)
            .mapToDataPoints()
        
        graph[.accQuant] = .init(
            points: quant,
            style: .init(
                color: Color(#colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)),
                lineWidth: 1,
                fill: Color(#colorLiteral(red: 0.5820686221, green: 0.8213914933, blue: 0.4178411639, alpha: 0.3774771341))
            )
        )
        
        invalidateHypnogram()
    }
    
    func updateHypnogramOverlays() {
        graph[.hypnoQuant1]?.clean()
        graph[.hypnoQuant2]?.clean()
        
        guard displayHypnoOverlay else { return }
        
        let points = detailViewModel.getMeasurements()
        guard !points.isEmpty else { return }
        
        let hrHCPoints = points.map(keyPathHR).mapToHCPoints()
        let overlay1 = detailViewModel.hypnogramComp
            .createOverlay(from: points, modelParams: modelParams)
            .map {$0.0}
            .toPoints(support: hrHCPoints)
            .mapToUnPoints()
            .mapToDataPoints()
        
        graph[.hypnoQuant1] = .init(
            points: overlay1,
            style: .init(
                color: Color(#colorLiteral(red: 0.3647058904, green: 0.06666667014, blue: 0.9686274529, alpha: 1)),
                lineWidth: 1,
                fill: Color(#colorLiteral(red: 0.2613111326, green: 0.7675498154, blue: 0.9810709246, alpha: 0.5870728532))
            )
        )
        
        let overlay2 = detailViewModel.hypnogramComp
            .createOverlay(from: points, modelParams: modelParams)
            .map {$0.1}
            .toPoints(support: hrHCPoints)
            .mapToUnPoints()
            .mapToDataPoints()
        
        graph[.hypnoQuant2] = .init(
            points: overlay2,
            style: .init(
                color: Color(#colorLiteral(red: 0.7450980544, green: 0.1568627506, blue: 0.07450980693, alpha: 1)),
                lineWidth: 1,
                fill: Color(#colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 0.4268054497))
            )
        )
    }
    
    func updateGyro() {
        graph[.gyro]?.clean()
        
        let points = detailViewModel.getMeasurements()
        guard !points.isEmpty else { return }
        
        let acc = points.map(keyPathGYRO)
            .mapToHCPoints()
            .normalize()
            .mapToUnPoints()
            .mapToDataPoints()
        
        graph[.gyro] = .init(
            points: acc,
            style: .init(
                color: .blue,
                lineWidth: 1,
            )
        )
        
        invalidateHypnogram()
    }
    
    func ShowDebugControlls() -> some View {
        VStack {
            HStack {
                Toggle(isOn: $displayHROverlay) {
                    Text("hr")
                }
                .toggleStyle(CheckboxToggleStyle(.leading))
                Toggle(isOn: $displayACCOverlay) {
                    Text("acc")
                }
                .toggleStyle(CheckboxToggleStyle(.leading))
                Toggle(isOn: $displayHypnoOverlay) {
                    Text("hypno")
                }
                .toggleStyle(CheckboxToggleStyle(.leading))
            }
            ScrollView(.vertical, showsIndicators: false) {
                VStack {
                    Text("frame size HR: \(Int(modelParams.frameSizeHR))")
                    Slider(value: $modelParams.frameSizeHR, in: 1...200, onEditingChanged: { _ in })
                    
                    Text("Quantization HR: \(modelParams.quantizationHR.format("%.2f"))")
                    Slider(value: $modelParams.quantizationHR, in: 0...1, onEditingChanged: { _ in })
                    
                    Divider().padding(5)
                    
                    Text("frame size ACC: \(Int(modelParams.frameSizeACC))")
                    Slider(value: $modelParams.frameSizeACC, in: 1...1000, onEditingChanged: { _ in })
                    
                    Text("Quantization ACC: \(modelParams.quantizationACC.format("%.2f"))")
                    Slider(value: $modelParams.quantizationACC, in: 0...1, onEditingChanged: { _ in })
                    
                    Button(action: {
                        showSettings = true
                    }, label: { Text("Set params") })
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.caption2)
                
            }
            .padding(10)
        }
        .foregroundColor(.textForeground)
        .background(Color.dialogBackground)
    }
#endif
}
