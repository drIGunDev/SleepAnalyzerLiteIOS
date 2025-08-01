//
//  ModelConfigurationParams+Extensions.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 01.08.25.
//

import Foundation
import HypnogramComputation

extension ModelConfigurationParams {
    func toModelConfigurationParamsAd() -> ModelConfigurationParamsAd {
        ModelConfigurationParamsAd(
            frameSizeHRMean: self.frameSizeHRMean,
            frameSizeHRRMSE: self.frameSizeHRRMSE,
            frameSizeACCMean: self.frameSizeACCMean,
            frameSizeACCRMSE: self.frameSizeACCRMSE,
            quantizationHR: self.quantizationHR,
            quantizationACC: self.quantizationACC
        )
    }
}
