//
//  Recorder.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 29.05.25.
//

import SwiftData
import Foundation

protocol MeasurementsRecorder: AnyObject {
    var isRecording: Bool { get }
    var series: SeriesDTO? { get }
    
    func startRecording() async throws
    func stopRecording(sleepQuality: SeriesDTO.SleepQuality) async throws
}
