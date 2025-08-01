//
//  PPGGraphView.swift
//  SleepAnalyzer
//
//  Created by Claude(Anthropic) on 12.06.25.
//

import SwiftUI
import Combine
import SwiftInjectLite

struct PPGGraphView: View {
    
    @Binding var viewModel: any PPGGraphViewModel
    
    let stepFactor: CGFloat = 0.8
    var curveColor: Color = .blue
    var topColorGradient: Color = .blue.opacity(0.7)
    var bottomColorGradient: Color = .blue.opacity(0.0)
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                createPath(geometry, isFilled: false)
                    .stroke(
                        curveColor,
                        lineWidth: 1
                    )
                
                createPath(geometry, isFilled: true)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [bottomColorGradient, topColorGradient]),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
            }
        }
    }
    
    // PPG waveform
    func createPath(_ geometry: GeometryProxy, isFilled: Bool) -> Path {
        Path { path in
            viewModel.maxPPGDataBufferSize = Int(geometry.size.width / stepFactor)
            
            guard !viewModel.ppgData.isEmpty else { return }
            
            let ppgData = viewModel.ppgData
            
            let height = geometry.size.height
            
            let firstPoint = ppgData[0]
            
            if isFilled {
                path.move(to: CGPoint(x: 0, y: height))
                path.addLine(to: CGPoint(x: 0, y: (1.0 - firstPoint) * height ))
            }
            else {
                path.move(to: CGPoint(x: 0, y: (1.0 - firstPoint) * height ))
            }
            
            // Add points for the waveform
            for i in 1..<ppgData.count {
                let x = stepFactor * CGFloat(i)
                let y = (1.0 - ppgData[i]) * height
                path.addLine(to: CGPoint(x: x, y: y))
                if isFilled && i == ppgData.count - 1 {
                    path.addLine(to: CGPoint(x: x, y: height))
                    path.closeSubpath()
                }
            }
        }
    }
}

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
    private var ppgObservableId: UUID?
    private var timer: Publishers.Autoconnect<Timer.TimerPublisher>?
    private var cancellables: Set<AnyCancellable> = []
    
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
        unsubscribeFromPPG()
        
        ppgObservableId = dataSource.ppgObservable.subscribe { [weak self] ppgData in
            self?.collect(ppgData)
        }
    }
    
    private func unsubscribeFromPPG() {
        guard let id = ppgObservableId else { return }
        dataSource.ppgObservable.unsubscribe(id)
        ppgObservableId = nil
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
