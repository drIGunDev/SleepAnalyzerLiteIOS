//
//  SensorScanner.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 15.04.25.
//

import Foundation
import Combine

protocol SensorScanner: Actor {
    var sensors: any Publisher<[SensorInfo], Never> { get }

    func scanSensors() async
    func cleanList() async
}
