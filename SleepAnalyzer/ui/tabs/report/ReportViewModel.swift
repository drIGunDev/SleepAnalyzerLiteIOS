//
//  ReportViewModel.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 23.07.25.
//

import SwiftUI
import SwiftInjectLite

enum ReportingState: Equatable {
    case idle
    case loading
    case loaded
    
    static func == (lhs: ReportingState, rhs: ReportingState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading), (.loaded, .loaded): return true
        default: return false
        }
    }
}

protocol ReportViewModel: ObservableObject {
    var reportingState: ReportingState { get }
    
    func performCrossReport()
    func map(_ keyPath: KeyPath<CrossReportItem, Double>) -> [UnPoint]
}

@Observable final class ReportViewModelImpl: ReportViewModel {
   
    var reportingState: ReportingState = .idle
    
    @ObservationIgnored @Inject(\.repository) private var repository
    @ObservationIgnored private var crossReport: [CrossReportItem] = []
    
    func map(_ keyPath: KeyPath<CrossReportItem, Double>) -> [UnPoint] {
        crossReport.map { UnPoint(x: $0.time.timeIntervalSince1970, y: Double($0[keyPath: keyPath])) }
    }
    
    func performCrossReport() {
        Task {
            reportingState = .loading
            await delay(0.2)
            let report = (try? await repository.getCrossReport()) ?? []
            self.reportingState = .loaded
            self.crossReport = report
        }
    }
}

// MARK: - DI

extension InjectionRegistry {
    var reportViewModel: any ReportViewModel {
        Self.instantiate(.factory) { ReportViewModelImpl() }
    }
}
