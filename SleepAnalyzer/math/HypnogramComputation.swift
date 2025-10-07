//
//  HypnogramComputation.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 17.06.25.
//

import Foundation
import HypnogramComputation
import SwiftInjectLite

protocol HypnogramComputation: AnyObject {
    func createOverlay(from measurements: [MeasurementDTO],
                       modelParams: any ModelConfigurationParams) -> [(HCSegment<HCSquareType>, HCSegment<HCSquareType>)]
    
    func createHypnogram(from measurements: [MeasurementDTO],
                         modelParams: any ModelConfigurationParams) -> [SleepPhase]
    
    func createUniformInput(from original: [UnPoint],
                            frameSize: Double,
                            quantization: Double) -> [UnPoint]
}

final private class HypnogramComputationImpl: HypnogramComputation {
    
    func createOverlay(from measurements: [MeasurementDTO],
                       modelParams: any ModelConfigurationParams) -> [(HCSegment<HCSquareType>, HCSegment<HCSquareType>)] {
        modelParams.reload()
        
        let binding = HypnogramComputationLib.init()
        let hr = measurements.map(\.heartRate).mapToHCPoints()
        let acc = measurements.map(\.acc).mapToHCPoints()
        return binding.createOverlay(
            hr: hr,
            acc: acc,
            modelParams: modelParams.toModelConfigurationParamsHC()
        )
    }
    
    func createHypnogram(from measurements: [MeasurementDTO],
                         modelParams: any ModelConfigurationParams) -> [SleepPhase] {
        modelParams.reload()
        
        let binding = HypnogramComputationLib.init()
        let hr = measurements.map(\.heartRate).mapToHCPoints()
        let acc = measurements.map(\.acc).mapToHCPoints()
        return binding.createHypnogram(
            hr: hr,
            acc: acc,
            modelParams: modelParams.toModelConfigurationParamsHC()
        )
        .mapToSleepPhases()
    }
    
    func createUniformInput(from original: [UnPoint],
                            frameSize: Double,
                            quantization: Double) -> [UnPoint] {
        let binding = HypnogramComputationLib.init()
        let original: [HCPoint] = original.mapToHCPoints()
        return binding.createUniformInput(
            from: original,
            frameSize: frameSize,
            quantization: quantization
        )
        .mapToUnPoints()
    }
}

// MARK: - DI

extension InjectionRegistry {
    var hypnogramComputation: any HypnogramComputation { Self.instantiate(.factory) { HypnogramComputationImpl.init() } }
}
