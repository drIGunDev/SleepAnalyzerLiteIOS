//
//  SleepAnalizer.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 26.05.25.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        TabView {
            TrackingView()
                .tabItem {
                    Image(systemName: "powersleep")
                    Text("Tracking")
                }
            ReportView()
                .tabItem {
                    Image(systemName: "waveform.badge.magnifyingglass")
                    Text("Report")
                }
            ArchiveView()
                .tabItem {
                    Image(systemName: "archivebox")
                    Text("Archive")
                }
        }
    }
}

struct MainViewContentView: View {
    var body: some View {
        MainView()
    }
}
struct SleepAnalizer_Previews: PreviewProvider {
    static var previews: some View {
        MainViewContentView()
    }
}
