//
//  PolarScannerImpl.swift
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
    
    private let apiProvider: BleApiProvider
    
    private let sensorsSubject = CurrentValueSubject<[SensorInfo], Never>([])
    var sensors: any Publisher<[SensorInfo], Never> { sensorsSubject.eraseToAnyPublisher() }
    
    private var sensorsList: [SensorInfo] = []
    private var polarApi: PolarBleApi!
    
    init(apiProvider: BleApiProvider) {
        self.apiProvider = apiProvider
        Task {
            let api = await (apiProvider.api as! PolarBleApi)
            await setPolarApi(api)
        }
    }
    
    func cleanList() async {
        sensorsList.removeAll()
        sensorsSubject.send([SensorInfo]())
        polarApi.cleanup()
    }
    
    private func setPolarApi(_ polarApi: PolarBleApi) {
        self.polarApi = polarApi
    }
}

extension PolarScannerImpl {
    
    func scanSensors() async {
        await cleanList()
        do {
            for try await device in polarApi.searchForDevice().values {
                await delay(1)
                sensorsList.append(SensorInfo.toSensorInfo(polarDevice: device))
                sensorsSubject.send(sensorsList)
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
