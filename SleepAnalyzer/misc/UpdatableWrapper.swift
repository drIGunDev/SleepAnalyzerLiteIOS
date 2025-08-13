//
//  UpdatableWrapper.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 13.08.25.
//

import SwiftUI

@Observable class UpdatableWrapper<T> {
    let wrappedValue: T
    private(set) var presentationId: UUID
    
    init(_ value: T) {
        self.wrappedValue = value
        self.presentationId = UUID()
    }
    
    func invalidateId() {
        presentationId = UUID()
    }
}
