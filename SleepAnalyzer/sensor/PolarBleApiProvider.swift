//
//  PolarBleApi.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 22.04.25.
//

import PolarBleSdk

protocol PolarBleApiProvider {
    var api: PolarBleApi { get set }
}
