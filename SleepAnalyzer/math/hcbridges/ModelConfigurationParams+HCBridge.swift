//
//  ModelConfigurationParams+HCBridge.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 01.08.25.
//

import Foundation
import HypnogramComputation

extension ModelConfigurationParams {
    func toModelConfigurationParamsHC() -> HCModelConfigurationParams {
        HCModelConfigurationParams(
            frameSizeHR: self.frameSizeHR,
            frameSizeACC: self.frameSizeACC,
            quantizationHR: self.quantizationHR,
            quantizationACC: self.quantizationACC,
            minSignificantIntervalSec: self.minSignificantIntervalSec,
            minAwakeDurationSec: self.minAwakeDurationSec,
            hrHiPassCutoff: self.hrHiPassCutoff,
            accHiPassCutoff: self.accHiPassCutoff
        )
    }
}
