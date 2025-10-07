//
//  PolarBleApiProvider.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 22.04.25.
//

import PolarBleSdk

protocol PolarBleApiProvider: Actor {
    var api: PolarBleApi { get set }
}
