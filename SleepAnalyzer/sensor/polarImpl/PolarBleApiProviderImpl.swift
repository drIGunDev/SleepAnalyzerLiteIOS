//
//  PolarBleApiProviderImpl.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 22.04.25.
//

import PolarBleSdk
import SwiftInjectLite

// MARK: - PolarBleApiProvider

final private actor PolarBleApiProviderImpl: PolarBleApiProvider {
    var api = PolarBleApiDefaultImpl.polarImplementation(
        DispatchQueue.main,
        features: [
            PolarBleSdkFeature.feature_hr,
            PolarBleSdkFeature.feature_battery_info,
            PolarBleSdkFeature.feature_device_info,
            PolarBleSdkFeature.feature_polar_online_streaming,
        ]
    )
}

extension InjectionRegistry {
    var apiProvider: any PolarBleApiProvider {
        Self.instantiate(.singleton) { PolarBleApiProviderImpl() }
    }
}
