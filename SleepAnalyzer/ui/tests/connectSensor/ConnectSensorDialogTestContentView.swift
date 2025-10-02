//
//  ScanSensorDialogTestContentView.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 23.04.25.
//

import SwiftUI
import SwiftInjectLite


struct ConnectSensorDialogTestContentView: View {
    
    @State var sensor = InjectionRegistry.inject(\.sensor)
    @State var selectedSensor: SensorInfo? = nil
    @State var showSheet = false
    @State var isConnected = false
    @State var errorMessage: String? = nil
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Sensor: \(selectedSensor?.name ?? "none")")
                    switch sensor.state {
                    case .disconnected:
                        Text("Disconnected").foregroundColor(Color.red)
                    case .connecting:
                        Text("Connecting...").foregroundColor(Color.orange)
                    case .connected:
                        Text("Connected").foregroundColor(Color.yellow)
                    case .streaming:
                        Text("Streaming").foregroundColor(Color.green)
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
                                try sensor.disconnect(removeFromStorage: false)
                                await delay(1)
                                if let deviceId = selectedSensor?.deviceId {
                                    try sensor.connect(to: deviceId)
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
                                try sensor.disconnect(removeFromStorage: false)
                                await delay(1)
                                try sensor.autoConnect()
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
                            try sensor.disconnect(removeFromStorage: false)
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
                    Text("Battery Level: \(sensor.batteryLevel)%")
                    Text("PowerOn: \(sensor.isBlePowerOn.description)")
                    Text("rssi: \(sensor.rssi)")
                    
                }
                Text(errorMessage ?? "")
            }
            .navigationTitle("Connect Sensor Test")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showSheet) {
                ScanSensorsDialog(selectedSensor: $selectedSensor, isPresented: $showSheet)
            }
        }
    }
}

struct ConnectSensorTestContentView_Previews: PreviewProvider {
    static var previews: some View {
        ConnectSensorDialogTestContentView()
    }
}
