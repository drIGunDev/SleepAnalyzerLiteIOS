//
//  DependencyInjections.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 28.05.25.
//

import SwiftUI
import SwiftInjectLite

// MARK: - DI

extension InjectionRegistry {
    var graphViewModel: any GraphViewModel { Self.instantiate(.factory) { GraphViewModelImpl.init() } }
    var archiveCellViewModel: any ArchiveCellViewModel { Self.instantiate(.factory) { ArchiveCellViewModelImpl.init() } }
    var detailViewModel: any DetailViewModel { Self.instantiate(.factory) { DetailViewModelImpl.init() } }
    var ppgGraphViewModel: any PPGGraphViewModel { Self.instantiate(.factory) { PPGGraphViewModelImpl.init() } }
    var modelConfigurationParams: any ModelConfigurationParams { Self.instantiate(.factory) { ModelConfigurationParamsImpl.init() } }
    var hypnogramColorMapping: any HypnogramColorMapping { Self.instantiate(.factory) { HypnogramColorMappingImpl.init() } }
    var graphRenderer: any GraphRenderer { Self.instantiate(.factory) { GraphRendererImpl.init() } }
    var repository: any Repository { Self.instantiate(.factory) { RepositoryImpl.init() } }
    var hypnogramComputation: any HypnogramComputation { Self.instantiate(.factory) { HypnogramComputationImpl.init() } }
}
