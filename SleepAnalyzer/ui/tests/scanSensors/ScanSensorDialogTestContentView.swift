//
//  ScanSensorDialogTestContentView.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 23.04.25.
//

import SwiftUI


struct ScanSensorDialogTestContentView: View {
    
    @State var selectedSensor: SensorInfo? = nil
    @State var showSheet = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Sensor: \(selectedSensor?.name ?? "none")")
                }
                Section {
                    Button(action: {
                        showSheet.toggle()
                    },label: {
                        Label("Select Sensor", systemImage: "sensor.fill")
                            .frame(maxWidth: .infinity)
                    })
                }
            }
            .navigationTitle("Select Sensor Test")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showSheet) {
                ScanSensorsDialog(selectedSensor: $selectedSensor, isPresented: $showSheet)
            }
        }
    }
}

struct SelectSensorTestContentView_Previews: PreviewProvider {
    static var previews: some View {
        ScanSensorDialogTestContentView()
    }
}
