//
//  PolarAPIImpl.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 16.04.25.
//

import Foundation
import SwiftUI
import PolarBleSdk
import SwiftInjectLite

// MARK: - API

// MARK: - SensorScanner

@Observable final class PolarScannerImpl: SensorScanner {
    
    @ObservationIgnored private let apiProvider: PolarBleApiProvider
    
    var sensors: [SensorInfo] = []
    
    init(apiProvider: PolarBleApiProvider) {
        self.apiProvider = apiProvider
    }
    
    func cleanList() {
        sensors.removeAll()
        apiProvider.api.cleanup()
    }
}

extension PolarScannerImpl {
    
    func scanSensors() async {
        cleanList()
        do {
            for try await device in self.apiProvider.api.searchForDevice().values {
                await delay(1)
                self.sensors.append(SensorInfo.toSensorInfo(polarDevice: device))
                Logger.d("device found: \(device)")
            }
        } catch let err {
            Logger.w("device search failed: \(err)")
        }
    }
}

// MARK: - DI

extension InjectionRegistry {
    var sensorScanner: any SensorScanner {
        get {
            let apiProvider = Self.inject(\.apiProvider)
            return Self.instantiate(.singleton) { PolarScannerImpl(apiProvider: apiProvider) }
        }
    }
}
