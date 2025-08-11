//
//  DetailView.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 23.06.25.
//

import SwiftUI
import SwiftInjectLite

struct DetailView: View {
    @State private var graphViewModel = InjectionRegistry.inject(\.graphViewModel)
    @State private var detailViewModel = InjectionRegistry.inject(\.detailViewModel)
    @State private var modelParams = InjectionRegistry.inject(\.modelConfigurationParams)
    
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
    
    init(series: SeriesDTO,
         isTabbarVisible: Binding<Bool>) {
        self._isTabbarVisible = isTabbarVisible
        self.detailViewModel.series = series
        self.currentMeasurementsCount = series.measurements.count
    }
    
    var body: some View {
        NavigationView {
            VStack {
                ShowTitle()
#if SA_DEBUG
                    .padding([.top, .bottom], 20)
#else
                    .padding([.top, .bottom], 40)
#endif
                LinearHypnogramView(sleepPhases: sleepPhases)
                    .padding([.leading], 35 + 5)
                    .padding([.trailing], 5)
#if SA_DEBUG
                    .frame(height: 80)
#else
                    .frame(height: 120)
#endif
                SleepPhaseStatisticView(sleepPhaseStatistics: .init(sleepPhases: sleepPhases))
                    .frame(height: 80)
                    .padding([.top, .bottom], 5)
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
                    xLabelProvider: { $0.toGraphXLabel(startTime: detailViewModel.series!.startTime, fontSize: 11) },
                    yLabelProvider: { $0.toGraphYLabel(fontSize: 11) }
                )
                .padding(5)
                .frame(height: 200)
                .id(graphId)
#if SA_DEBUG
                ShowDebugControlls()
#endif
                Spacer()
            }
            .padding(.horizontal)
        }
        // HR
        .task(id: detailViewModel.series?.measurements.count ?? 0) {
            updateHR()
            updateHypnogram()
        }
#if SA_DEBUG
        // ACC
        .task(id: Double(currentMeasurementsCount)) {
            updateACC()
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
    
    func invalidateGraph() {
        self.graphId += 1
    }
    
    func updateHR() {
        let points = detailViewModel.getMeasurements()
        guard !points.isEmpty else { return }
        
        currentMeasurementsCount = points.count
        
        let original = points.map(keyPathHR)
        graphViewModel.setPoints(forKey: .heartRate, points: original, isAxisLabel: true, color: .heartRate, fillColor: nil, forcedSetCurrentSlot: true)
        graphViewModel.rescale()
        
        invalidateGraph()
    }
    
    func updateHypnogram() {
        let points = detailViewModel.getMeasurements()
        guard !points.isEmpty else { return }
        
        sleepPhases = detailViewModel.hypnogramComp.createHypnogram(from: points, modelParams: modelParams)
        invalidateGraph()
    }
    
#if SA_DEBUG
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
                    
                    Text("Quantization HR: \(modelParams.quantizationHR)")
                    Slider(value: $modelParams.quantizationHR, in: 0...1, onEditingChanged: { _ in })
                    
                    Divider().padding(5)
                    
                    Text("frame size ACC: \(Int(modelParams.frameSizeACC))")
                    Slider(value: $modelParams.frameSizeACC, in: 1...1000, onEditingChanged: { _ in })
                    
                    Text("Quantization ACC: \(modelParams.quantizationACC)")
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
    
    func updateHRMean() {
        guard displayHROverlay else {
            graphViewModel.removeSlot(forKey: 100)
            invalidateGraph()
            return
        }
        let points = detailViewModel.getMeasurements()
        guard !points.isEmpty else { return }
        
        let original = points.map(keyPathHR)
        let median = original.mapToHCPoints().mean(frameSize: Int(modelParams.frameSizeHR)).mapToUnPoints()
        graphViewModel.setPoints(forKey: 100, points: median, isAxisLabel: false, color: Color(#colorLiteral(red: 0.7254902124, green: 0.4784313738, blue: 0.09803921729, alpha: 1)), fillColor: nil, forcedSetCurrentSlot: false)
        invalidateGraph()
    }
    
    func updateHRRMSE() {
        guard displayHROverlay else {
            graphViewModel.removeSlot(forKey: 101)
            graphViewModel.removeSlot(forKey: 102)
            invalidateGraph()
            return
        }
        let points = detailViewModel.getMeasurements()
        guard !points.isEmpty else { return }
        
        let original = points.map(keyPathHR)
        let rmse = original.mapToHCPoints().rmse(frameSize: Int(modelParams.frameSizeHR)).mapToUnPoints()
        graphViewModel.setPoints(forKey: 101, points: rmse, isAxisLabel: false, color: .blue, fillColor: nil, forcedSetCurrentSlot: false)
        
        let operations = detailViewModel.hypnogramComp.createUniformInput(from: original,
                                                                          frameSize: modelParams.frameSizeHR,
                                                                          quantization: modelParams.quantizationHR)
        graphViewModel.setPoints(forKey: 102, points: operations, isAxisLabel: false, color: Color(#colorLiteral(red: 0.8549019694, green: 0.250980407, blue: 0.4784313738, alpha: 1)), fillColor: Color(#colorLiteral(red: 0.7647058964, green: 0.3967176876, blue: 0.393351266, alpha: 0.5)), forcedSetCurrentSlot: false)
        invalidateGraph()
    }
    
    func updateACC() {
        let points = detailViewModel.getMeasurements()
        guard !points.isEmpty else { return }
        
        let original = points.map(keyPathACC)
        let normalized = original.mapToHCPoints().normalize().mapToUnPoints()
        graphViewModel.setPoints(forKey: .acc, points: normalized, isAxisLabel: false, color: .green, fillColor: nil, forcedSetCurrentSlot: true)
        invalidateGraph()
    }
    
    func updateACCMean() {
        guard displayACCOverlay else {
            graphViewModel.removeSlot(forKey: 105)
            invalidateGraph()
            return
        }
        let points = detailViewModel.getMeasurements()
        guard !points.isEmpty else { return }
        
        let original = points.map(keyPathACC)
        let median = original.mapToHCPoints().mean(frameSize: Int(modelParams.frameSizeACC)).normalize().mapToUnPoints()
        graphViewModel.setPoints(forKey: 105, points: median, isAxisLabel: false, color: Color(#colorLiteral(red: 0.5843137503, green: 0.8235294223, blue: 0.4196078479, alpha: 1)), fillColor: nil, forcedSetCurrentSlot: false)
        invalidateGraph()
    }
    
    func updateACCRMSE() {
        guard displayACCOverlay else {
            graphViewModel.removeSlot(forKey: 111)
            graphViewModel.removeSlot(forKey: 112)
            invalidateGraph()
            return
        }
        let points = detailViewModel.getMeasurements()
        guard !points.isEmpty else { return }
        
        let original = points.map(keyPathACC)
        let rmse = original.mapToHCPoints().rmse(frameSize: Int(modelParams.frameSizeACC)).mapToUnPoints()
        graphViewModel.setPoints(forKey: 111, points: rmse, isAxisLabel: false, color: .blue, fillColor: nil, forcedSetCurrentSlot: false)
        
        let operations = detailViewModel.hypnogramComp.createUniformInput(from: original,
                                                                          frameSize: modelParams.frameSizeACC,
                                                                          quantization: modelParams.quantizationACC)
        graphViewModel.setPoints(forKey: 112, points: operations, isAxisLabel: false, color: Color(#colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)), fillColor: Color(#colorLiteral(red: 0.5820686221, green: 0.8213914933, blue: 0.4178411639, alpha: 0.3774771341)), forcedSetCurrentSlot: false)
        invalidateGraph()
    }
    
    func updateHypnogramOverlays() {
        guard displayHypnoOverlay  else {
            graphViewModel.removeSlot(forKey: 130)
            graphViewModel.removeSlot(forKey: 131)
            invalidateGraph()
            return
        }
        let points = detailViewModel.getMeasurements()
        guard !points.isEmpty else { return }
        
        let hr = detailViewModel.getMeasurements().map(keyPathHR).mapToHCPoints()
        let overlay1 = detailViewModel.hypnogramComp.createOverlay(from: points, modelParams: modelParams)
            .map { $0.0}
            .toPoints(support: hr)
            .mapToUnPoints()
        graphViewModel.setPoints(forKey: 130, points: overlay1, isAxisLabel: false, color: Color(#colorLiteral(red: 0.3647058904, green: 0.06666667014, blue: 0.9686274529, alpha: 1)), fillColor: Color(#colorLiteral(red: 0.2613111326, green: 0.7675498154, blue: 0.9810709246, alpha: 0.5870728532)), forcedSetCurrentSlot: false)
        
        let overlay2 = detailViewModel.hypnogramComp.createOverlay(from: points, modelParams: modelParams)
            .map { $0.1}
            .toPoints(support: hr)
            .mapToUnPoints()
        graphViewModel.setPoints(forKey: 131, points: overlay2, isAxisLabel: false, color: Color(#colorLiteral(red: 0.7450980544, green: 0.1568627506, blue: 0.07450980693, alpha: 1)), fillColor: Color(#colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 0.4268054497)), forcedSetCurrentSlot: false)
        invalidateGraph()
    }
#endif
}
