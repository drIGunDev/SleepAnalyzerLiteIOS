//
//  ReportView.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 23.07.25.
//

import SwiftUI
import SwiftInjectLite

struct ReportView: View {
    
    @State private var reportViewModel = InjectionRegistry.inject(\.reportViewModel)
    @State private var graphHRViewModel = InjectionRegistry.inject(\.graphViewModel)
    @State private var graphSleepPhasesViewModel = InjectionRegistry.inject(\.graphViewModel)
    
    @State private var displayHRAvr = true
    @State private var displayHRMin = true
    @State private var displayHRMax = true
    
    @State private var displayAwake = true
    @State private var displayLightSleep = true
    @State private var displayDeepSleep = true
    @State private var displayREM = true
    
    
    private typealias GraphType = (keyPath: KeyPath<CrossReportItem, Double>, color: Color)
    private enum GraphTypes {
        static let hrAvg: GraphType = (keyPath: \.hrAvg, color: .heartRate)
        static let hrMin: GraphType = (keyPath: \.hrMin, color: Color(#colorLiteral(red: 0.9568627477, green: 0.6588235497, blue: 0.5450980663, alpha: 1)))
        static let hrMax: GraphType = (keyPath: \.hrMax, color: Color(#colorLiteral(red: 0.8078431487, green: 0.02745098062, blue: 0.3333333433, alpha: 1)))
        
        static let awake: GraphType = (keyPath: \.awake, color: HypnogramColorsDefault.awake)
        static let lightSleep: GraphType = (keyPath: \.lightSleep, color: HypnogramColorsDefault.lightSleep)
        static let deepSleep: GraphType = (keyPath: \.deepSleep, color: HypnogramColorsDefault.deepSleep)
        static let remSleep: GraphType = (keyPath: \.rem, color: HypnogramColorsDefault.rem)
    }
    
    init() {
        graphHRViewModel.isSlotsBounded = true
        graphSleepPhasesViewModel.isSlotsBounded = true
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.mainBackground.ignoresSafeArea(edges: .all)
                
                if reportViewModel.reportingState == .loading {
                    ProgressView(value: nil, total: 1.0)
                        .tint(.blue)
                        .padding(.vertical, 20)
                }
                else {
                    ScrollView {
                        VStack {
                            ShowHR()
                            ShowSleepPhases()
                        }
                    }
                }
            }
            .navigationTitle("Report")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: reportViewModel.performCrossReport)
            .task(id: reportViewModel.reportingState == .loaded) {
                updatAllGraphs()
            }
            .task(id: displayHRAvr) {
                updateHRAvr()
            }
            .task(id: displayHRMin) {
                updateHRMin()
            }
            .task(id: displayHRMax) {
                updateHRMax()
            }
            .task(id: displayAwake) {
                updateAwake()
            }
            .task(id: displayLightSleep) {
                updateLightSleep()
            }
            .task(id: displayDeepSleep) {
                updateDeepSleep()
            }
            .task(id: displayREM) {
                updateRem()
            }
        }
    }
}

extension ReportView {
    
    private func updatAllGraphs() {
        updateHRAvr()
        updateHRMin()
        updateHRMax()
        
        updateAwake()
        updateLightSleep()
        updateDeepSleep()
        updateRem()
    }
    
    private func updateHRAvr() {
        graphHRViewModel.removeSlot(forKey: GraphTypes.hrAvg.keyPath.hashValue)
        if displayHRAvr {
            updateHRGraph(GraphTypes.hrAvg)
        }
    }
    
    private func updateHRMax() {
        graphHRViewModel.removeSlot(forKey: GraphTypes.hrMax.keyPath.hashValue)
        if displayHRMax {
            updateHRGraph(GraphTypes.hrMax)
        }
    }
    
    private func updateHRMin() {
        graphHRViewModel.removeSlot(forKey: GraphTypes.hrMin.keyPath.hashValue)
        if displayHRMin {
            updateHRGraph(GraphTypes.hrMin)
        }
    }
    
    private func updateAwake() {
        graphSleepPhasesViewModel.removeSlot(forKey: GraphTypes.awake.keyPath.hashValue)
        if displayAwake {
            updateHypnoGraph(GraphTypes.awake)
        }
    }
    
    private func updateLightSleep() {
        graphSleepPhasesViewModel.removeSlot(forKey: GraphTypes.lightSleep.keyPath.hashValue)
        if displayLightSleep {
            updateHypnoGraph(GraphTypes.lightSleep)
        }
    }
    
    private func updateDeepSleep() {
        graphSleepPhasesViewModel.removeSlot(forKey: GraphTypes.deepSleep.keyPath.hashValue)
        if displayDeepSleep {
            updateHypnoGraph(GraphTypes.deepSleep)
        }
    }
    
    private func updateRem()  {
        graphSleepPhasesViewModel.removeSlot(forKey: GraphTypes.remSleep.keyPath.hashValue)
        if displayREM {
            updateHypnoGraph(GraphTypes.remSleep)
        }
    }
    
    private func updateHRGraph(_ graphType: GraphType) {
        self.updateGraph(graphType, graph: graphHRViewModel)
    }
    
    private func updateHypnoGraph(_ graphType: GraphType) {
        self.updateGraph(graphType, graph: graphSleepPhasesViewModel)
    }
    
    private func updateGraph(_ graphType: GraphType, graph: any GraphViewModel) {
        let report = reportViewModel.map(graphType.keyPath)
        guard report.count > 0 else { return }
        
        graph.setPoints(
            forKey: graphType.keyPath.hashValue,
            points: report,
            isAxisLabel: true,
            color: graphType.color,
            fillColor: nil,
            forcedSetCurrentSlot: false
        )
    }
}

extension ReportView {
    
    func ShowHR() -> some View {
        return VStack(alignment: .leading) {
            Text("HBR(bpm)")
                .frame(maxWidth: .infinity, alignment: .center)
                .font(.headline)
                .padding([.top, .bottom], 10)
            
            GraphView(
                viewModel: $graphHRViewModel,
                configuration: GraphView.Configuration(
                    xGridCount: 3,
                    yGridCount: 4,
                    xGridAxisCount: 3,
                    yGridAxisCount: 4,
                    xGap: 35,
                    yGap: 30
                ),
                xLabelProvider: { (Date(timeIntervalSince1970: $0).format("dd.MM"), Font.system(size: 11)) },
                yLabelProvider: { $0.toGraphYLabel(fontSize: 11) }
            )
            .frame(height: 200)
            .id(graphHRViewModel.invalidatedId)
            .padding([.leading, .trailing], 10)
            
            VStack(alignment: .center, spacing: 10) {
                HStack {
                    Toggle(isOn: $displayHRAvr) {
                        Text("HR avr.")
                    }
                    .toggleStyle(CheckboxToggleStyle(.trailing, GraphTypes.hrAvg.color))
                    Toggle(isOn: $displayHRMin) {
                        Text("HR min")
                    }
                    .toggleStyle(CheckboxToggleStyle(.trailing, GraphTypes.hrMin.color))
                    Toggle(isOn: $displayHRMax) {
                        Text("HR max")
                    }
                    .toggleStyle(CheckboxToggleStyle(.trailing, GraphTypes.hrMax.color))
                }
            }
            .font(.caption)
            .padding(.leading, 20)
            .frame(maxWidth: .infinity)
        }
    }
    
    func ShowSleepPhases() -> some View {
        return VStack(alignment: .leading) {
            Text("Hypnogram (h)")
                .frame(maxWidth: .infinity, alignment: .center)
                .font(.headline)
                .padding(.top, 20)
                .padding(.bottom, 10)
            
            GraphView(
                viewModel: $graphSleepPhasesViewModel,
                configuration: GraphView.Configuration(
                    xGridCount: 3,
                    yGridCount: 4,
                    xGridAxisCount: 3,
                    yGridAxisCount: 4,
                    xGap: 35,
                    yGap: 30
                ),
                xLabelProvider: { (Date(timeIntervalSince1970: $0).format("dd.MM"), Font.system(size: 11)) },
                yLabelProvider: { ($0.toDurationInHour().format("%.0f"), Font.system(size: 11)) }
            )
            .frame(height: 200)
            .id(graphSleepPhasesViewModel.invalidatedId)
            .padding([.leading, .trailing], 10)
            
            VStack(alignment: .center, spacing: 10) {
                HStack {
                    Toggle(isOn: $displayAwake) {
                        Text("Awake")
                    }
                    .toggleStyle(CheckboxToggleStyle(.trailing, GraphTypes.awake.color))
                    Toggle(isOn: $displayLightSleep) {
                        Text("Light sleep")
                    }
                    .toggleStyle(CheckboxToggleStyle(.trailing, GraphTypes.lightSleep.color))
                    Toggle(isOn: $displayDeepSleep) {
                        Text("Deep sleep")
                    }
                    .toggleStyle(CheckboxToggleStyle(.trailing, GraphTypes.deepSleep.color))
                }
                Toggle(isOn: $displayREM) {
                    Text("REM")
                }
                .toggleStyle(CheckboxToggleStyle(.trailing, GraphTypes.remSleep.color))
            }
            .font(.caption)
            .padding(.leading, 20)
            .frame(maxWidth: .infinity)
            .padding([.leading, .trailing], 10)
        }
    }
}
