//
//  ScanSensorDialogTestContentView.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 23.04.25.
//

import SwiftUI
import SwiftInjectLite

struct DataSourceSensorDialogTestContentView: View {
    
    @State var sensorDS = InjectionRegistry.inject(\.sensorDataSource)
    @State var selectedSensor: SensorInfo? = nil
    @State var showSheet: Bool = false
    @State var isConnected: Bool = false
    @State var errorMessage: String? = nil
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Selected Sensor: \(selectedSensor?.name ?? "none")")
                    switch sensorDS.sensor.state {
                    case .disconnected:
                        Text("Disconnected").foregroundColor(Color.red)
                    case .connecting:
                        Text("Connecting...").foregroundColor(Color.orange)
                    case .connected(let sensor):
                        Text("Connected: \(sensor.deviceId)").foregroundColor(Color.yellow)
                    case .streaming(let seonsorId):
                        Text("Streaming: \(seonsorId)").foregroundColor(Color.green)
                    }
                }
                
                Section {
                    Button(action: {
                        errorMessage = nil
                        showSheet.toggle()
                    },label: {
                        Text("Select Sensor")
                    })
                }
                .frame(maxWidth: .infinity)
                .alignmentGuide(.listRowSeparatorLeading) { $0[.leading] }
                
                Section {
                    
                    Button(action: {
                        Task{
                            do {
                                errorMessage = nil
                                try sensorDS.sensor.disconnect(removeFromStorage: false)
                                await delay(1)
                                if let deviceId = selectedSensor?.deviceId {
                                    try sensorDS.sensor.connect(to: deviceId)
                                }
                                else {
                                    errorMessage = "No sensor selected"
                                }
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                        }
                    },label: {
                        Text("Connect")
                    })
                    
                    Button(action: {
                        Task{
                            do {
                                errorMessage = nil
                                try sensorDS.sensor.disconnect(removeFromStorage: false)
                                await delay(1)
                                try sensorDS.sensor.autoConnect()
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                        }
                    },label: {
                        Text("Auto Connect")
                    })
                    
                    Button(action: {
                        do {
                            errorMessage = nil
                            try sensorDS.sensor.disconnect(removeFromStorage: false)
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    },label: {
                        Text("Disconnect")
                    })
                }
                .frame(maxWidth: .infinity)
                .alignmentGuide(.listRowSeparatorLeading) { $0[.leading] }
                
                Section {
                    Text("Battery Level: \(sensorDS.sensor.batteryLevel)%")
                    Text("PowerOn: \(sensorDS.sensor.isBlePowerOn)")
                    Text("hr: \(sensorDS.hr)")
                    Text("rssi: \(sensorDS.sensor.rssi)")
                    Text("acc: \(sensorDS.acc)")
                }
                Text(errorMessage ?? "")
            }
            .navigationTitle("Data Source Test")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showSheet) {
                ScanSensorsDialog(selectedSensor: $selectedSensor, isPresented: $showSheet)
            }
        }
    }
}

struct DataSourceSensorTestContentView_Previews: PreviewProvider {
    static var previews: some View {
        DataSourceSensorDialogTestContentView()
    }
}
