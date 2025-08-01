//
//  AnalysisTolls.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 17.06.25.
//

import Foundation
import HypnogramComputation

protocol HypnogramComputation {
    func createOverlay(from measurements: [MeasurementDTO],
                       modelParams: any ModelConfigurationParams) -> [(Segment<Square>, Segment<Square>)]
    
    func createHypnogram(from measurements: [MeasurementDTO],
                         modelParams: any ModelConfigurationParams) -> [SleepPhase]
    
    func createRMSENormInverseQuan(from original: [UnPoint],
                                   frameSizeMean: Double,
                                   frameSizeRMSE: Double,
                                   quantization: Double) -> [UnPoint]
}

final class HypnogramComputationImpl: HypnogramComputation {
     
    func createOverlay(from measurements: [MeasurementDTO],
                       modelParams: any ModelConfigurationParams) -> [(Segment<Square>, Segment<Square>)] {
        let binding = HypnogramComputationLib.init()
        let hr = measurements.map(\.heartRate).mapToUnPointAds()
        let acc = measurements.map(\.acc).mapToUnPointAds()
        return binding.createOverlay(
            hr: hr,
            acc: acc,
            modelParams: modelParams.toModelConfigurationParamsAd()
        )
    }
    
    func createHypnogram(from measurements: [MeasurementDTO],
                         modelParams: any ModelConfigurationParams) -> [SleepPhase] {
        let binding = HypnogramComputationLib.init()
        let hr = measurements.map(\.heartRate).mapToUnPointAds()
        let acc = measurements.map(\.acc).mapToUnPointAds()
        return binding.createHypnogram(
            hr: hr,
            acc: acc,
            modelParams: modelParams.toModelConfigurationParamsAd()
        )
            .mapToSleepPhases()
    }
    
    func createRMSENormInverseQuan(from original: [UnPoint],
                                   frameSizeMean: Double,
                                   frameSizeRMSE: Double,
                                   quantization: Double) -> [UnPoint] {
        let binding = HypnogramComputationLib()
        let originalAd: [UnPointAd] = original.mapToUnPointAds()
        return binding.createRMSENormInverseQuan(
            from: originalAd,
            frameSizeMean: frameSizeMean,
            frameSizeRMSE: frameSizeRMSE,
            quantization: quantization
        )
            .mapToUnPoints()
    }
}
