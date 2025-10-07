//
//  TestObservationTracking.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 11.07.25.
//

import SwiftUI

@Observable final class ObservableCounter {
    var count: Int = 0
    var count2: Int = 0
    
    func startIncrementing() {
        Task {
            for i in 0..<10 {
                increment1()
                if i.isMultiple(of: 10) {
                    increment2()
                }
                await delay(1)
            }
        }
    }
    
    private func increment1() {
        count += 1
    }
    
    private func increment2() {
        count2 += 1
    }
}

protocol InClassTracker {}

extension InClassTracker {
    public func withObservationTracking(execute: @Sendable @escaping () -> Void) {
        Observation.withObservationTracking {
            execute()
        } onChange: {
            self.withObservationTracking(execute: execute)
        }
    }
}

@Observable final class ObserverCounter: InClassTracker {
    let counter = ObservableCounter()
    
    func increment() {
        counter.startIncrementing()
    }
    
    func observe() {
        withObservationTracking { [weak self] in
           guard let self else { return }
           print("\(counter.count) \(counter.count2)")
         }
        
    }
}

struct TestObserverCounter: View {
    @State private var counter: ObserverCounter = .init()
    
    var body: some View {
        Text("\(counter.counter.count) \(counter.counter.count2)")
            .task {
                counter.increment()
            }
    }
}

struct Previews: PreviewProvider {
    static var previews: some View {
        TestObserverCounter()
    }
}
