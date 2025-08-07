//
//  AppParams.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 03.07.25.
//

import Foundation
import SwiftUI
import SwiftInjectLite

protocol ModelConfigurationParams: ObservableObject {
    var frameSizeHRMean: Double { get set }
    var frameSizeHRRMSE: Double { get set }
    var frameSizeACCMean: Double { get set }
    var frameSizeACCRMSE: Double { get set }
    var quantizationHR: Double { get set }
    var quantizationACC: Double { get set }
}

@Observable final class ModelConfigurationParamsImpl: ModelConfigurationParams {
    
    var frameSizeHRMean: Double {
        didSet {
            AppSettings.shared.frameSizeHRMean = frameSizeHRMean
        }
    }
    
    var frameSizeHRRMSE: Double {
        didSet {
            AppSettings.shared.frameSizeHRRMSE = frameSizeHRRMSE
        }
    }
    
    var frameSizeACCMean: Double {
        didSet {
            AppSettings.shared.frameSizeACCMean = frameSizeACCMean
        }
    }
    
    var frameSizeACCRMSE: Double {
        didSet {
            AppSettings.shared.frameSizeACCRMSE = frameSizeACCRMSE
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
    
    init() {
        self.frameSizeHRMean = AppSettings.shared.frameSizeHRMean
        self.frameSizeHRRMSE = AppSettings.shared.frameSizeHRRMSE
        self.frameSizeACCMean = AppSettings.shared.frameSizeACCMean
        self.frameSizeACCRMSE = AppSettings.shared.frameSizeACCRMSE
        self.quantizationHR = AppSettings.shared.quantizationHR
        self.quantizationACC = AppSettings.shared.quantizationACC
    }
}

// MARK: - DI

extension InjectionRegistry {
    var modelConfigurationParams: any ModelConfigurationParams { Self.instantiate(.factory) { ModelConfigurationParamsImpl.init() } }
}
