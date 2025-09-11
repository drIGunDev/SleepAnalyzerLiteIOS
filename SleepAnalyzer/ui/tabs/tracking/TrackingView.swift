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
    
    @State private var sensorDataSource = InjectionRegistry.inject(\.sensorDataSource)
    
    @State private var trackingViewModel = InjectionRegistry.inject(\.trackingViewModel)
    @State private var ppgViewModel = InjectionRegistry.inject(\.ppgGraphViewModel)
    
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
                                sensorID: sensorDataSource.sensor.connectedSensor?.id ?? "",
                                batteryLevel: sensorDataSource.sensor.batteryLevel,
                                rssi: sensorDataSource.sensor.rssi,
                                status: sensorDataSource.sensor.state
                            )
                            .padding(.bottom, 15)
                        }
                    }
                    
                    ShowSelectSensorButton()
                        
                    HypnogramTrackingView(trackingViewModel: $trackingViewModel.hypnogramTrackingViewModel) {
                        VStack (spacing: 20) {
                            if isSensorConnected {
                                PPGGraphView(
                                    viewModel: $ppgViewModel,
                                    curveColor: .construction,
                                    topColorGradient: .construction,
                                    bottomColorGradient: .mainBackground
                                )
                                    .frame(width: CGFloat(150), height: 40)
                            }
                            ShowHeartRateLabel()
                            ShowStartStopTrackingButton()
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
                    ScanSensorsDialog(selectedSensor: $selectedSensor, isPresented: $showSelectSensorSheet) {
                        connectToSensor(selectedSensor)
                    }
                }
                .navigationTitle("Tracking")
                .navigationBarTitleDisplayMode(.inline)
                .padding()
            }
        }
        .popup(isPresented: $showSatisfactionDialog,
               dialog: ShowSatisfactionDialog(cancelAction: { },
                                              okAction: {
            trackingViewModel.stopTracking(sleepQuality: $0)
            graph.removeAll()
            withAnimation {
                isTrackingActive.toggle()
            }
        }))
        .onAppear {
            autoConnectIfDisconnected()
        }
        .onAppear {
            trackingViewModel.startUIUpdate()
            ppgViewModel.start()
        }
        .onDisappear {
            trackingViewModel.stopUIUpdate()
            ppgViewModel.stop()
        }
        .onChange(of: scenePhase) { _, newPhase in
            checkActivityInBackgroundMode(newPhase)
        }
        .task(id: sensorDataSource.sensor.state) {
            withAnimation(.default) {
                isSensorConnected = sensorDataSource.sensor.state != .disconnected
            }
        }
        .task(id: trackingViewModel.series?.measurements.count) {
            updateGraph()
        }
    }
}

extension TrackingView {
    
    func autoConnectIfDisconnected() {
        guard !sensorDataSource.sensor.isConnected else { return }
        Task{
            do {
                errorMessage = nil
                try sensorDataSource.sensor.disconnect(removeFromStorage: false)
                await delay(2)
                try sensorDataSource.sensor.autoConnect()
            } catch {
                errorMessage = "Problem by connection to Sensor"
            }
        }
    }
    
    func connectToSensor(_ sensor: SensorInfo?) {
        Task{
            do {
                errorMessage = nil
                try sensorDataSource.sensor.disconnect(removeFromStorage: false)
                await delay(2)
                if let deviceId = selectedSensor?.deviceId {
                    try sensorDataSource.sensor.connect(to: deviceId)
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
    
    func checkActivityInBackgroundMode(_ newPhase: ScenePhase) {
        switch newPhase {
        case .background:
            ppgViewModel.stop()
            trackingViewModel.stopUIUpdate()
        case .active:
            ppgViewModel.start()
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
        Text("\(sensorDataSource.hr == 0 ? "--" : String(sensorDataSource.hr)) BPM")
            .foregroundColor(isSensorConnected ? .red : .disabled)
            .font(.system(size: 20, weight: .bold))
    }
}

extension TrackingView {
    
    func ShowTrackingTimeLabel() -> some View {
        Group {
            if let series = self.trackingViewModel.series {
                Text("\(series.startTime.format("yyyy.MM.dd HH:mm")) - \(Date().format("HH:mm:ss"))")
                    .font(.system(size: 13))
                    .lineLimit(1)
                    .minimumScaleFactor(0.3)
            }
        }
    }
}

extension TrackingView {
    
    func ShowStartStopTrackingButton() -> some View {
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
