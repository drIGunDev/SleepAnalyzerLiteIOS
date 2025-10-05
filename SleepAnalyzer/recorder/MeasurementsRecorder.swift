//
//  Recorder.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 29.05.25.
//

import SwiftData
import Foundation

protocol MeasurementsRecorder: Actor {
    @MainActor var isRecording: Bool { get }
    @MainActor var series: SeriesDTO? { get }
    
    func startRecording() async throws
    func stopRecording(sleepQuality: SeriesDTO.SleepQuality) async throws
}
