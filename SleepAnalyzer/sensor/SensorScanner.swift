//
//  SensorAPI.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 15.04.25.
//

import Foundation

//
// use @Environment(\.sensorScanner) var sensorScanner
//
protocol SensorScanner: ObservableObject {
    var sensors: [SensorInfo] { get }
    
    init(apiProvider: PolarBleApiProvider) 

    func scanSensors() async
    func cleanList()
}
