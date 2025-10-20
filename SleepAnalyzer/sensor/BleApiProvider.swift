//
//  PolarBleApiProvider.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 22.04.25.
//

import PolarBleSdk

protocol BleApiProvider: Actor {
    var api: Any { get set }
}
