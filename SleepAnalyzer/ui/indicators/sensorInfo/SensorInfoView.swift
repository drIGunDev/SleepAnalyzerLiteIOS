//
//  SensorInfoView.swift
//  SleepAnalyzer
//
//  Created by Claude(Anthropic) on 26.05.25.
//

import SwiftUI

struct SensorInfoView: View {
    let sensorID: String
    let batteryLevel: UInt
    let rssi: Int
    var status: SensorState
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 7) {
            // Sensor ID
            HStack {
                Text("sensor_id".localized())
                Text(sensorID.count == 0 ? "unknown".localized(with: "") : sensorID)
                    .font(.system(size: 14, weight: .medium))
            }
            
            // Battery level with indicator
            HStack () {
                Text("battery_level".localized(with: batteryLevel))
                BatteryIndicatorView(batteryLevel: batteryLevel)
                    .frame(width: 30, height: 10)
            }
            
            // RSSI value
            HStack {
                Text("rssi".localized(with: rssi))
                RSSIIndicatorView(rssi: rssi)
                    .frame(width: 20, height: 15)
            }
            
            // Connection status
            sensorState
                .font(.system(size: 14))
        }
        .background(Color.mainBackground)
        .foregroundColor(.textForeground)
        .font(.system(size: 13))
        .cornerRadius(10)
        .lineLimit(1)
        .minimumScaleFactor(0.3)
    }
    
    var sensorState: Text {
        switch status {
        case .disconnected:
            Text("Disconnected").foregroundColor(Color.red)
        case .connecting:
            Text("Connecting...").foregroundColor(Color.orange)
        case .connected:
            Text("Connected").foregroundColor(Color.yellow)
        case .streaming:
            Text("STREAMING").foregroundColor(Color.green)
        }
    }
}

struct SensorInfoView_Previews: PreviewProvider {
    static var previews: some View {
        SensorInfoView(
            sensorID: "D838D02D",
            batteryLevel: 70,
            rssi: -50,
            status: .streaming("")
        )
    }
}
