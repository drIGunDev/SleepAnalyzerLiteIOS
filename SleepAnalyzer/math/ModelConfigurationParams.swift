//
//  ModelConfigurationParams.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 03.07.25.
//

import Foundation
import SwiftUI
import SwiftInjectLite

protocol ModelConfigurationParams: ObservableObject, AnyObject {
    var frameSizeHR: Double { get set }
    var frameSizeACC: Double { get set }
    var quantizationHR: Double { get set }
    var quantizationACC: Double { get set }
    var minSignificantIntervalSec: Double { get }
    var minAwakeDurationSec: Double { get }
    var hrHiPassCutoff: Double { get }
    var accHiPassCutoff: Double { get }
    
    func reload()
}

@Observable final class ModelConfigurationParamsImpl: ModelConfigurationParams {
    
    var frameSizeHR: Double {
        didSet {
            AppSettings.shared.frameSizeHR = frameSizeHR
        }
    }
    
    var frameSizeACC: Double {
        didSet {
            AppSettings.shared.frameSizeACC = frameSizeACC
        }
    }

    var quantizationHR: Double {
        didSet {
            AppSettings.shared.quantizationHR = quantizationHR
        }
    }
    
    var quantizationACC: Double {
        didSet {
            AppSettings.shared.quantizationACC = quantizationACC
        }
    }
    
    let minSignificantIntervalSec: Double = 60
    let minAwakeDurationSec: Double = 10 * 60
    let hrHiPassCutoff: Double = 80.0
    let accHiPassCutoff: Double = 400.0
    
    init() {
        self.frameSizeHR = AppSettings.shared.frameSizeHR
        self.frameSizeACC = AppSettings.shared.frameSizeACC
        self.quantizationHR = AppSettings.shared.quantizationHR
        self.quantizationACC = AppSettings.shared.quantizationACC
    }
    
    func reload() {
        self.frameSizeHR = AppSettings.shared.frameSizeHR
        self.frameSizeACC = AppSettings.shared.frameSizeACC
        self.quantizationHR = AppSettings.shared.quantizationHR
        self.quantizationACC = AppSettings.shared.quantizationACC
    }
}

// MARK: - DI

extension InjectionRegistry {
    var modelConfigurationParams: any ModelConfigurationParams { Self.instantiate(.factory) { ModelConfigurationParamsImpl.init() } }
}
