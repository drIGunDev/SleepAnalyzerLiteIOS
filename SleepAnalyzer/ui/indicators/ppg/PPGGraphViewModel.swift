//
//  PPGGraphViewModel.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 28.08.25.
//
import SwiftUI
import Combine
import SwiftInjectLite

protocol PPGGraphViewModel: ObservableObject {
    var ppgData: [CGFloat] { get set }
    var maxPPGDataBufferSize: Int { get set }
    
    func start()
    func stop()
}

@Observable final class PPGGraphViewModelImpl: PPGGraphViewModel {
    
    var ppgData: [CGFloat] = []
    
    @ObservationIgnored var maxPPGDataBufferSize: Int = 0
    @ObservationIgnored var timePeriod: TimeInterval = 0.2

    @ObservationIgnored @Inject(\.sensorDataSource) private var dataSource

    private var buffer: [CGFloat] = []
    private var isSubscribedToPPG: Bool = false
    private var timer: Publishers.Autoconnect<Timer.TimerPublisher>?
    private var cancellables: Set<AnyCancellable> = []
    
    init() {
        dataSource.ppgObservableSubject.sink { [weak self] ppgData in
            guard self?.isSubscribedToPPG == true else { return }
            self?.collect(ppgData)
        }
        .store(in: &cancellables)
    }
    
    deinit {
        stop()
    }
    
    func start() {
        resetBuffers()
        startTimer()
        subscribeToPPG()
    }
    
    func stop() {
        stopTimer()
        unsubscribeFromPPG()
    }

    private func subscribeToPPG() {
        isSubscribedToPPG = true
    }
    
    private func unsubscribeFromPPG() {
        isSubscribedToPPG = false
    }
    
    private func startTimer() {
        stopTimer()
        
        timer = Timer.publish(every: timePeriod, on: .main, in: .common).autoconnect()
        timer?.sink { [weak self] _ in
            self?.swap()
        }
        .store(in: &cancellables)
    }
    
    private func stopTimer() {
        timer?.upstream.connect().cancel()
        timer = nil
    }
    
    private func collect(_ chunk: PPGData) {
        add(normalize(chunk))
    }
    
    private func resetBuffers() {
        buffer.removeAll()
        ppgData.removeAll()
    }
    
    private func swap() {
        guard buffer.count > 0 else { return }
        
        let delta = min(Int(Double(buffer.count) * timePeriod), buffer.count)
        
        if delta > 0 {
            ppgData.append(contentsOf: buffer[0...(delta - 1)])
        }
        buffer.removeFirst(delta)
        if ppgData.count > maxPPGDataBufferSize {
            ppgData.removeFirst(ppgData.count - maxPPGDataBufferSize)
        }
    }
    
    private func add(_ chunk: [CGFloat]) {
        buffer.append(contentsOf: chunk)
    }
    
    private func normalize(_ ppgData: PPGData) -> [CGFloat] {
        let max: CGFloat = CGFloat(ppgData.max(by: { $0.sample < $1.sample })?.sample ?? 0)
        let min: CGFloat = CGFloat(ppgData.min(by: { $0.sample < $1.sample })?.sample ?? 0)
        return ppgData.map { (max - CGFloat($0.sample)) / (max - min) }
    }
}

// MARK: - DI

extension InjectionRegistry {
    var ppgGraphViewModel: any PPGGraphViewModel { Self.instantiate(.factory) { PPGGraphViewModelImpl.init() } }
}
