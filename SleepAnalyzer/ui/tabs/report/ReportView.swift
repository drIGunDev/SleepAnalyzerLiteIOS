//
//  ReportView.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 23.07.25.
//

import SwiftUI
import SwiftInjectLite
import Linea

struct ReportView: View {
    
    @State private var reportViewModel = InjectionRegistry.inject(\.reportViewModel)
    
    @State private var graphHR: [GraphIds : LinearSeries] = [:]
    @State private var graphSleepPhase: [GraphIds : LinearSeries] = [:]
    
    @State private var displayHRAvr = true
    @State private var displayHRMin = true
    @State private var displayHRMax = true
    
    @State private var displayAwake = true
    @State private var displayLightSleep = true
    @State private var displayDeepSleep = true
    @State private var displayREM = true

    enum GraphIds: Int {
        case hrAvg, hrMin, hrMax, awake, lightSleep, deepSleep, remSleep
    }
    private typealias GraphType = (keyPath: KeyPath<CrossReportItem, Double>, color: Color, id: GraphIds)
    private enum GraphTypes {
        static let hrAvg: GraphType = (keyPath: \.hrAvg, color: .heartRate, .hrAvg)
        static let hrMin: GraphType = (keyPath: \.hrMin, color: Color(#colorLiteral(red: 0.9568627477, green: 0.6588235497, blue: 0.5450980663, alpha: 1)), .hrMin)
        static let hrMax: GraphType = (keyPath: \.hrMax, color: Color(#colorLiteral(red: 0.8078431487, green: 0.02745098062, blue: 0.3333333433, alpha: 1)), .hrMax)
        
        static let awake: GraphType = (keyPath: \.awake, color: HypnogramColorsDefault.awake, .awake)
        static let lightSleep: GraphType = (keyPath: \.lightSleep, color: HypnogramColorsDefault.lightSleep, .lightSleep)
        static let deepSleep: GraphType = (keyPath: \.deepSleep, color: HypnogramColorsDefault.deepSleep, .deepSleep)
        static let remSleep: GraphType = (keyPath: \.rem, color: HypnogramColorsDefault.rem, .remSleep)
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
        graphHR[.hrAvg]?.clean()
        if displayHRAvr {
            updateHRGraph(GraphTypes.hrAvg)
        }
    }
    
    private func updateHRMax() {
        graphHR[.hrMax]?.clean()
        if displayHRMax {
            updateHRGraph(GraphTypes.hrMax)
        }
    }
    
    private func updateHRMin() {
        graphHR[.hrMin]?.clean()
        if displayHRMin {
            updateHRGraph(GraphTypes.hrMin)
        }
    }
    
    private func updateAwake() {
        graphSleepPhase[.awake]?.clean()
        if displayAwake {
            updateHypnoGraph(GraphTypes.awake)
        }
    }
    
    private func updateLightSleep() {
        graphSleepPhase[.lightSleep]?.clean()
        if displayLightSleep {
            updateHypnoGraph(GraphTypes.lightSleep)
        }
    }
    
    private func updateDeepSleep() {
        graphSleepPhase[.deepSleep]?.clean()
        if displayDeepSleep {
            updateHypnoGraph(GraphTypes.deepSleep)
        }
    }
    
    private func updateRem()  {
        graphSleepPhase[.remSleep]?.clean()
        if displayREM {
            updateHypnoGraph(GraphTypes.remSleep)
        }
    }
     
    private func updateHRGraph(_ graphType: GraphType) {
        let report = reportViewModel.map(graphType.keyPath)
        guard report.count > 0 else { return }
        
        graphHR[graphType.id] = .init(
            points: report.mapToDataPoints(),
            style: .init(
                color: graphType.color,
                lineWidth: 1,
                smoothing: .bSpline(degree: 10,
                                    knots: nil,
                                    samplesPerSpan: 5,
                                    parameterization: .openUniform)
            )
        )
    }
    
    private func updateHypnoGraph(_ graphType: GraphType) {
        let report = reportViewModel.map(graphType.keyPath)
        guard report.count > 0 else { return }
        
        graphSleepPhase[graphType.id] = .init(
            points: report.mapToDataPoints(),
            style: .init(
                color: graphType.color,
                lineWidth: 1,
                smoothing: .bSpline(degree: 10,
                                    knots: nil,
                                    samplesPerSpan: 5,
                                    parameterization: .openUniform)
            )
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
            
            LinearGraph(
                series: graphHR,
                xAxis: XAxis(
                    autoRange: .none,
                    tickProvider: NiceTickProvider(),
                    formatter: AnyAxisFormatter.init {
                        (Date(timeIntervalSince1970: $0).format("dd.MM"), Font.system(size: 11))
                    }
                ),
                yAxes: YAxes.bind(
                    axis: YAxis(
                        autoRange: .none,
                        tickProvider: FixedCountTickProvider(),
                        formatter: AnyAxisFormatter.init {
                            $0.toGraphYLabel(fontSize: 11)
                        }
                    ),
                    to: [.hrAvg, .hrMin, .hrMax]
                ),
                style: .init(
                    gridOpacity: 0.9,
                    cornerRadius: 0,
                    background: Color.mainBackground,
                    xTickTarget: 3,
                    yTickTarget: 4
                ),
                panMode: .x,
                zoomMode: .x
            )
            .frame(height: 200)
            .padding([.leading, .trailing], 20)

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
            
            LinearGraph(
                series: graphSleepPhase,
                xAxis: XAxis(
                    autoRange: .none,
                    tickProvider: NiceTickProvider(),
                    formatter: AnyAxisFormatter.init {
                        (Date(timeIntervalSince1970: $0).format("dd.MM"), Font.system(size: 11))
                    }
                ),
                yAxes: YAxes.bind(
                    axis: YAxis(
                        autoRange: .none,
                        tickProvider: FixedCountTickProvider(),
                        formatter: AnyAxisFormatter.init {
                            ($0.toDurationInHour().format("%.0f"), Font.system(size: 11))
                        }
                    ),
                    to: [.remSleep, .deepSleep, .lightSleep, .awake]
                ),
                style: .init(
                    gridOpacity: 0.9,
                    cornerRadius: 0,
                    background: Color.mainBackground,
                    xTickTarget: 4,
                    yTickTarget: 5
                ),
                panMode: .x,
                zoomMode: .x
            )
            .frame(height: 200)
            .padding([.leading, .trailing], 20)
            
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
