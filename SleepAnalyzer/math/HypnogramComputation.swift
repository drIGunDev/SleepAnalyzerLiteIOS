//
//  AnalysisTolls.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 17.06.25.
//

import Foundation
import HypnogramComputation
import SwiftInjectLite

protocol HypnogramComputation {
    func createOverlay(from measurements: [MeasurementDTO],
                       modelParams: any ModelConfigurationParams) -> [(HCSegment<Square>, HCSegment<Square>)]
    
    func createHypnogram(from measurements: [MeasurementDTO],
                         modelParams: any ModelConfigurationParams) -> [SleepPhase]
    
    func createRMSENormInverseQuan(from original: [UnPoint],
                                   frameSizeMean: Double,
                                   frameSizeRMSE: Double,
                                   quantization: Double) -> [UnPoint]
}

final class HypnogramComputationImpl: HypnogramComputation {
     
    func createOverlay(from measurements: [MeasurementDTO],
                       modelParams: any ModelConfigurationParams) -> [(HCSegment<Square>, HCSegment<Square>)] {
        let binding = HypnogramComputationLib.init()
        let hr = measurements.map(\.heartRate).mapToUnPointHCPoints()
        let acc = measurements.map(\.acc).mapToUnPointHCPoints()
        return binding.createOverlay(
            hr: hr,
            acc: acc,
            modelParams: modelParams.toModelConfigurationParamsHC()
        )
    }
    
    func createHypnogram(from measurements: [MeasurementDTO],
                         modelParams: any ModelConfigurationParams) -> [SleepPhase] {
        let binding = HypnogramComputationLib.init()
        let hr = measurements.map(\.heartRate).mapToUnPointHCPoints()
        let acc = measurements.map(\.acc).mapToUnPointHCPoints()
        return binding.createHypnogram(
            hr: hr,
            acc: acc,
            modelParams: modelParams.toModelConfigurationParamsHC()
        )
            .mapToSleepPhases()
    }
    
    func createRMSENormInverseQuan(from original: [UnPoint],
                                   frameSizeMean: Double,
                                   frameSizeRMSE: Double,
                                   quantization: Double) -> [UnPoint] {
        let binding = HypnogramComputationLib()
        let originalAd: [HCPoint] = original.mapToUnPointHCPoints()
        return binding.createRMSENormInverseQuan(
            from: originalAd,
            frameSizeMean: frameSizeMean,
            frameSizeRMSE: frameSizeRMSE,
            quantization: quantization
        )
            .mapToUnPoints()
    }
}

// MARK: - DI

extension InjectionRegistry {
    var hypnogramComputation: any HypnogramComputation { Self.instantiate(.factory) { HypnogramComputationImpl.init() } }
}
