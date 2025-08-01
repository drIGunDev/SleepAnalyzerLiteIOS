//
//  Recorder.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 29.05.25.
//

import SwiftData
import Foundation

//
// use @Environment(\.measurementsRecorder) var recorder
//
protocol MeasurementsRecorder {
    var isRecording: Bool { get }
    var series: SeriesDTO? { get }
    
    func startRecording()
    func stopRecording(sleepQuality: SeriesDTO.SleepQuality)
}
