//
//  SensorScan.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 22.04.25.
//

import SwiftUI
import SwiftInjectLite

struct ScanSensorsDialog: View {
    
    @State private var sensorScanner = InjectionRegistry.inject(\.sensorScanner) 
    
    @Binding var selectedSensor: SensorInfo?
    @Binding var isPresented: Bool
    
    var okAction: (() -> Void)? = nil
    
    var body: some View {
        NavigationView {
            List {
                let header = Text("Please select a sensor from the list below:")
                    .font(.dialogText)
                let footer = HStack {
                    ProgressView(value: nil, total: 1.0)
                        .tint(.blue)
                        .padding(.vertical, 20)
                }
                    .frame(maxWidth: .infinity)
                
                Section(header: header, footer: footer) {
                    ForEach(sensorScanner.sensors, id: \.id) { sensor in
                        Text(sensor.name)
                            .onTapGesture { _ in
                                selectedSensor = sensor
                                isPresented.toggle()
                                okAction?()
                            }
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.accentColor)
                    }
                }
                .textCase(nil)
                .padding(.vertical, 8)
                .listRowSeparator(.hidden)
            }
            .task {
                await sensorScanner.scanSensors()
            }
            .navigationTitle(Text("Select Sensor"))
            .navigationBarItems(trailing: Button("Cancel") { isPresented.toggle() }.foregroundColor(.accentColor))
            .navigationBarTitleDisplayMode(.inline)
            .animation(.easeIn(duration: 0.75), value: sensorScanner.sensors)
            .foregroundColor(.textForeground)
            .onDisappear { sensorScanner.cleanList() }
        }
    }
}

struct SensorScanDialog_Previews: PreviewProvider {
    @State static var selectedSensor: SensorInfo? = nil
    @State static var presented: Bool = false
    
    static var previews: some View {
        ScanSensorsDialog(selectedSensor: $selectedSensor, isPresented: $presented)
            .preferredColorScheme(.dark)
    }
}
