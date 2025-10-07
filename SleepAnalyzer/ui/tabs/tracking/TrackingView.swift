//
//  TrackingView.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 21.05.25.
//

import SwiftUI
import SwiftInjectLite
import Linea

struct TrackingView: View {
    
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var trackingViewModel = InjectionRegistry.inject(\.trackingViewModel)
    
    enum GraphIds: Int { case hr }
    @State private var graph: [GraphIds : LinearSeries] = [:]
    
    @State private var isTrackingActive = false
    @State private var isSensorConnected = false
    
    @State private var selectedSensor: SensorInfo? = nil
    @State private var showSelectSensorSheet = false
    @State private var showSatisfactionDialog = false
    
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(Color.mainBackground).edgesIgnoringSafeArea(.all)
                VStack {
                    HStack (alignment: .top) {
                        if isTrackingActive && isSensorConnected {
                            VStack(alignment: .leading) {
                                ShowTrackingTimeLabel()
                                ShowGraphView()
                                    .padding(.trailing, 15)
                                    .padding(.top, 5)
                            }
                        }
                        else {
                            Spacer()
                        }
                        
                        if isSensorConnected {
                            SensorInfoView(
                                sensorID: trackingViewModel.sensorId ?? "",
                                batteryLevel: trackingViewModel.sensorBatteryLevel,
                                rssi: trackingViewModel.sensorRSSI,
                                status: trackingViewModel.sensorState
                            )
                            .padding(.bottom, 15)
                        }
                    }
                    
                    ShowSelectSensorButton()
                    
                    HypnogramTrackingView(trackingViewModel: $trackingViewModel.hypnogramTrackingViewModel) {
                        VStack (spacing: 20) {
                            if isSensorConnected {
                                PPGView(
                                    viewModel: $trackingViewModel.ppgViewModel,
                                    style: .init(
                                        color: Color(#colorLiteral(red: 0.0007766221637, green: 1, blue: 0.2145778206, alpha: 1)),
                                        lineWidth: 2
                                    )
                                )
                                .frame(width: CGFloat(180), height: 50)
                            }
                            ShowHeartRateLabel()
                            ShowTrackingButton()
                        }
                    }
                    
                    if let errorMessage = errorMessage {
                        Text("\(errorMessage)")
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .sheet(isPresented: $showSelectSensorSheet) {
                    ScanSensorsDialog(selectedSensor: $selectedSensor,
                                      isPresented: $showSelectSensorSheet) {
                        connectToSensor(selectedSensor)
                    }
                }
                .navigationTitle("Tracking")
                .navigationBarTitleDisplayMode(.inline)
                .padding()
            }
        }
        .popup(
            isPresented: $showSatisfactionDialog,
            dialog: ShowSatisfactionDialog(
                cancelAction: { },
                okAction: {
                    trackingViewModel.stopTracking(sleepQuality: $0)
                    graph.removeAll()
                    withAnimation { isTrackingActive.toggle()}
                }
            )
        )
        .onAppear {
            autoConnectIfDisconnected()
        }
        .onAppear {
            trackingViewModel.startUIUpdate()
        }
        .onDisappear {
            trackingViewModel.stopUIUpdate()
        }
        .onChange(of: scenePhase) { _, newPhase in
            checkIsInBackground(newPhase)
        }
        .task(id: trackingViewModel.sensorIsConnected) {
            withAnimation(.default) {
                isSensorConnected = trackingViewModel.sensorIsConnected
            }
        }
        .task(id: trackingViewModel.series?.measurements.count) {
            updateGraph()
        }
    }
}

extension TrackingView {
    
    func autoConnectIfDisconnected() {
        guard !trackingViewModel.sensorIsConnected else { return }
        
        Task{
            do {
                errorMessage = nil
                try await trackingViewModel.sensor.disconnect(removeFromStorage: false)
                await delay(2)
                try await trackingViewModel.sensor.autoConnect()
            } catch {
                errorMessage = "Problem by connection to Sensor"
            }
        }
    }
    
    func connectToSensor(_ sensor: SensorInfo?) {
        Task{
            do {
                errorMessage = nil
                try await trackingViewModel.sensor.disconnect(removeFromStorage: false)
                await delay(2)
                if let deviceId = selectedSensor?.deviceId {
                    try await trackingViewModel.sensor.connect(to: deviceId)
                }
                else {
                    errorMessage = "No sensor setected"
                }
            } catch {
                errorMessage = "Problem by connection to Sensor"
            }
        }
    }
}

extension TrackingView {
    
    func updateGraph() {
        guard let series = trackingViewModel.series else { return }
        
        let hr = series.measurements.map(\.heartRate).mapToDataPoints()
        graph[.hr] = .init(
            points: hr,
            style: .init(
                color: .red,
                lineWidth: 1,
            )
        )
    }
}

extension TrackingView {
    
    func checkIsInBackground(_ newPhase: ScenePhase) {
        switch newPhase {
        case .background:
            trackingViewModel.stopUIUpdate()
        case .active:
            trackingViewModel.startUIUpdate()
        case .inactive: ()
        @unknown default: Logger.w("Unknown scene phase")
        }
    }
}

extension TrackingView {
    
    func ShowSelectSensorButton() -> some View {
        HStack {
            Spacer()
            Button("Select Sensor") {
                showSelectSensorSheet.toggle()
            }
            .disabled(isTrackingActive)
        }
    }
}

extension TrackingView {
    
    func ShowGraphView() -> some View {
        LinearGraph(
            series: graph,
            xAxis: XAxis(
                autoRange: .none,
                tickProvider: FixedCountTickProvider(),
                formatter: AnyAxisFormatter.init {
                    guard let series = self.trackingViewModel.series else { return ("", .system(size: 11)) }
                    return $0.toGraphXLabel(startTime: series.startTime, fontSize: 9)
                }
            ),
            yAxes: YAxes.bind(
                axis: YAxis(
                    autoRange: .padded(),
                    tickProvider: FixedCountTickProvider(),
                    formatter: AnyAxisFormatter.init {
                        $0.toGraphYLabel(fontSize: 11)
                    }
                ),
                to: [.hr]
            ),
            style: .init(
                gridOpacity: 0.9,
                cornerRadius: 0,
                background: Color.mainBackground,
                xTickTarget: 3,
                yTickTarget: 3
            ),
            panMode: .none,
            zoomMode: .none
        )
        .frame(height: 80)
    }
    
    func ShowHeartRateLabel() -> some View {
        Text("\(trackingViewModel.hr == 0 ? "--" : String(trackingViewModel.hr)) BPM")
            .foregroundColor(isSensorConnected ? .red : .disabled)
            .font(.system(size: 20, weight: .bold))
    }
}

extension TrackingView {
    
    func ShowTrackingTimeLabel() -> some View {
        Group {
            if let series = self.trackingViewModel.series {
                Text("\(series.startTime.format("yyyy.MM.dd HH:mm")) - \(Date().format("HH:mm"))")
                    .font(.system(size: 13))
                    .lineLimit(1)
                    .minimumScaleFactor(0.3)
            }
        }
    }
}

extension TrackingView {
    
    func ShowTrackingButton() -> some View {
        Button(
            action: {
                if isTrackingActive {
                    showSatisfactionDialog = true
                }
                else {
                    trackingViewModel.startTracking()
                    withAnimation {
                        isTrackingActive.toggle()
                    }
                }
            },
            label: {
                if isTrackingActive {
                    Text("Stop tracking")
                        .padding(5)
                        .foregroundColor(.black)
                        .background(
                            RoundedRectangle( cornerRadius: 10, style: .continuous)
                                .fill(isSensorConnected ? Color.accentColor : .disabled)
                        )
                }
                else {
                    Text("Start tracking")
                        .padding(5)
                        .foregroundColor(isSensorConnected ? .accentColor : .disabled)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(isSensorConnected ? Color.accentColor : .disabled, lineWidth: 2)
                        )
                }
            }
        )
        .disabled(!isSensorConnected)
    }
}

struct TrackingView_Previews: PreviewProvider {
    static var previews: some View {
        TrackingView()
    }
}
