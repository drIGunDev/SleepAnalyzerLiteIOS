//
//  AppSettings.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 24.04.25.
//

import Foundation

struct AppSettings {
    
    @UserDefaultsAppSetting(key: "sensor.sensorId")
    public var sensorId: String?
    
    @UserDefaultsAppSetting(key: "sensor.frameSizeHRMean")
    public var frameSizeHR: Double = 74.0

    @UserDefaultsAppSetting(key: "sensor.frameSizeACCMean")
    public var frameSizeACC: Double = 92.0

    @UserDefaultsAppSetting(key: "sensor.quantizationHR")
    public var quantizationHR: Double = 0.928
    
    @UserDefaultsAppSetting(key: "sensor.quantizationACC")
    public var quantizationACC: Double = 0.959
    
    @UserDefaultsAppSetting(key: "scale.autoscale")
    public var autoscale: Bool = true
    
    @UserDefaultsAppSetting(key: "scale.minHR")
    public var minHR: Double? = 40.0
    
    @UserDefaultsAppSetting(key: "scale.maxHR")
    public var maxHR: Double? = 100.0
    
    public static var shared = AppSettings()
    private init() {}
}

extension AppSettings {
    
    func toRescaleParams() -> GraphRescaleParams {
        autoscale ? .autoscale : .scale(min: AppSettings.shared.minHR, max: AppSettings.shared.maxHR)
    }
}
