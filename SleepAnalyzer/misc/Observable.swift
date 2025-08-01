//
//  Observable.swift
//  SleepAnalyzer
//
//  Created by Dolores(chatGPT) on 01.06.25.
//

import Foundation

final class ObservableEvent<Value: Sendable>: @unchecked Sendable {
    typealias Subscriber = (Value) -> Void
    private var subscribers: [UUID: Subscriber] = [:]
    private let queue = DispatchQueue(label: "ObservableEventQueue", attributes: .concurrent)
    
    func subscribe(_ subscriber: @escaping Subscriber) -> UUID {
        let id = UUID()
        queue.async(flags: .barrier) { [weak self] in
            self?.subscribers[id] = subscriber
        }
        return id
    }
    
    func unsubscribe(_ id: UUID) {
        queue.async(flags: .barrier) { [weak self] in
            self?.subscribers.removeValue(forKey: id)
        }
    }
    
    func accept(_ value: Value) {
        queue.async { [weak self] in
            self?.subscribers.values.forEach { $0(value) }
        }
    }
}
