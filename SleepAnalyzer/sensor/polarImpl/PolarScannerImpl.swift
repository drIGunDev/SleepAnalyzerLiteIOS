//
//  PolarAPIImpl.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 16.04.25.
//

import Foundation
import Combine
import PolarBleSdk
import SwiftInjectLite

// MARK: - API

// MARK: - SensorScanner

private actor PolarScannerImpl: SensorScanner {
    
    private let apiProvider: PolarBleApiProvider
    
    let sensors: any Publisher<[SensorInfo], Never> = CurrentValueSubject([])
    private var sensorsList: [SensorInfo] = []
    
    init(apiProvider: PolarBleApiProvider) {
        self.apiProvider = apiProvider
    }
    
    func cleanList() async {
        sensorsList.removeAll()
        sensors.asCurrentValueSubject().send([SensorInfo]())
        await apiProvider.api.cleanup()
    }
}

extension PolarScannerImpl {
    
    func scanSensors() async {
        await cleanList()
        do {
            for try await device in await self.apiProvider.api.searchForDevice().values {
                await delay(1)
                sensorsList.append(SensorInfo.toSensorInfo(polarDevice: device))
                sensors.asCurrentValueSubject().send(sensorsList)
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
