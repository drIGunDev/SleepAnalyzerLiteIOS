//
//  SleepAnalizerApp.swift
//  SleepAnalizer
//
//  Created by Igor Gun on 03.04.25.
//

import SwiftUI

@main
struct SleepAnalizerApp: App {
    init () {
        Logger.setLevel(.verbose)
    }
    
    var body: some Scene {
        WindowGroup {
            MainViewContentView()
                .preferredColorScheme(.dark)
        }
    }
}
