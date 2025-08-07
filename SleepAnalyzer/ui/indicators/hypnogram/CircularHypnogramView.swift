//
//  CircleHypnogram.swift
//  SleepAnalyzer
//
//  Created by Claude(Anthropic) on 06.05.25.
//

import SwiftUI
import SwiftInjectLite

protocol HypnogramViewModel: ObservableObject {
    var sleepPhases: [SleepPhase] { get set }
    var startTime: Date? { get set }
    
    func startTracking(startTime: Date)
    func updateTracking(sleepPhases: [SleepPhase])
}

@Observable class HypnogramViewModelImpl: HypnogramViewModel {
    var sleepPhases: [SleepPhase]
    var startTime: Date?
    
    init(sleepPhases: [SleepPhase] = [], startTime: Date? = nil) {
        self.sleepPhases = sleepPhases
        self.startTime = startTime
    }
    
    func startTracking(startTime: Date) {
        self.startTime = startTime
    }
    
    func updateTracking(sleepPhases: [SleepPhase]) {
        self.sleepPhases.removeAll()
        self.sleepPhases.append(contentsOf: sleepPhases)
    }
}

struct CircularHypnogramView<Content: View>: View {
    
    @Binding var viewModel: any HypnogramViewModel

    let colorMapping = InjectionRegistry.inject(\.hypnogramColorMapping)
    var ringThickness: CGFloat = 10
    var gapBetweenRings: CGFloat = 30
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        ZStack {
            Canvas {
                context,
                size in
                guard let startTime = viewModel.startTime else { return }
                guard !viewModel.sleepPhases.isEmpty else { return }
                
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = min(size.width, size.height) / 2 - gapBetweenRings
                
                var startAngle = getStartAngleFromDate(startTime)
                
                for (index, phase) in viewModel.sleepPhases.enumerated() {
                    let sweepAngle = .pi * phase.durationSeconds / 21600
                    
                    let path = Path { p in
                        p.addArc(
                            center: center,
                            radius: radius - ringThickness / 2,
                            startAngle: Angle(radians: Double(startAngle)),
                            endAngle: Angle(radians: Double(startAngle + sweepAngle)),
                            clockwise: false
                        )
                    }
                    
                    let color: Color = colorMapping.map(toColorFor: phase.state)
                    
                    let lineCap: CGLineCap
                    if index == 0 || index == viewModel.sleepPhases.count - 1 {
                        lineCap = .round
                    }
                    else {
                        lineCap = .butt
                    }
                    
                    context.stroke(
                        path,
                        with: .color(color),
                        style: StrokeStyle(lineWidth: ringThickness, lineCap: lineCap)
                    )
                    
                    startAngle += sweepAngle
                }
            }
            
            content()
        }
    }
    
    private func getStartAngleFromDate(_ date: Date) -> CGFloat {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)  % 12
        let minute = calendar.component(.minute, from: date)
        let hourInRadians = 2 * CGFloat.pi * CGFloat(hour) / 12
        let minuteInRadians = 2 * CGFloat.pi * CGFloat(minute) / (12 * 60)
        return hourInRadians + minuteInRadians - CGFloat.pi / 2
    }
}

let hypnogramTestData: [SleepPhase] = [
    SleepPhase(state: .awake, durationSeconds: 60 * 60),
    SleepPhase(state: .lightSleep, durationSeconds: 45 * 60),
    SleepPhase(state: .deepSleep, durationSeconds: 90 * 60),
    SleepPhase(state: .rem, durationSeconds: 35 * 60),
    SleepPhase(state: .lightSleep, durationSeconds: 60 * 60),
    SleepPhase(state: .deepSleep, durationSeconds: 75 * 60),
    SleepPhase(state: .rem, durationSeconds: 30 * 60),
    SleepPhase(state: .lightSleep, durationSeconds: 40 * 60),
    SleepPhase(state: .awake, durationSeconds: 10 * 60)
]

func dateFromString(_ dateString: String, format: String) -> Date? {
    let formatter = DateFormatter()
    formatter.dateFormat = format
    return formatter.date(from: dateString)
}

private struct CircularHypnogramViewTest: View {
    
    @State var viewModel: any HypnogramViewModel =
    HypnogramViewModelImpl(sleepPhases: hypnogramTestData,
                           startTime: dateFromString("2025-05-07 15:00:00", format: "yyyy-MM-dd HH:mm:ss")!)
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            CircularHypnogramView(
                viewModel: $viewModel
            )
            {
                Text("Сон")
                    .font(.title)
                    .fontWeight(.bold)
            }
            .frame(height: .infinity)
        }
    }
}


struct CircularHypnogramView_Previews: PreviewProvider {
    static var previews: some View {
        CircularHypnogramViewTest()
    }
}

@Observable class MockHypnogramViewModel: HypnogramViewModel {
    var sleepPhases: [SleepPhase] = []
    var startTime: Date? = Date()
    var isRunningSimulation = false
    
    private let definedSleepPhases: [SleepPhase] = hypnogramTestData
    
    func startTracking(startTime: Date) {
        self.startTime = startTime
    }
    
    func startSimulation() {
        Task {
            isRunningSimulation = true
            Task{ @MainActor in sleepPhases.removeAll() }
            for time in stride(from: 0, to: 60 * 60 * 12, by: 60) {
                let slice = getHypnogramSlice(until: TimeInterval(time))
                Task{ @MainActor in updateTracking(sleepPhases: slice.0) }
                if slice.1 { break }
                await delay(0.1)
            }
            isRunningSimulation = false
        }
    }
    
    func updateTracking(sleepPhases: [SleepPhase]) {
        self.sleepPhases.removeAll()
        self.sleepPhases.append(contentsOf: sleepPhases)
    }
    
    private func getHypnogramSlice(until time: TimeInterval) -> ([SleepPhase], Bool) {
        var result: [SleepPhase] = []
        var breakSimulation = false
        var phaseTime: TimeInterval = 0
        for (index, phase) in definedSleepPhases.enumerated()  {
            if phaseTime + TimeInterval(phase.durationSeconds) <= time {
                phaseTime += TimeInterval(phase.durationSeconds)
                result.append(phase)
                if index == definedSleepPhases.count - 1 {
                    breakSimulation = true
                }
            }
            else {
                let particalPhase = SleepPhase(state: phase.state, durationSeconds: time - phaseTime)
                result.append(particalPhase)
                break
            }
            
        }
        return (result, breakSimulation)
    }
}

struct CircularHypnogramViewDynamicTestContentView: View {
    @State var viewModel: any HypnogramViewModel = MockHypnogramViewModel()
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            CircularHypnogramView(
                viewModel: $viewModel
            )
            {
                Button("Start simuation") {
                    (viewModel as! MockHypnogramViewModel).startSimulation()
                }
                .disabled((viewModel as! MockHypnogramViewModel).isRunningSimulation)
            }
        }
    }
}

struct CircularHypnogramViewDynamic_Preview: PreviewProvider {
    static var previews: some View {
        CircularHypnogramViewDynamicTestContentView()
    }
}
