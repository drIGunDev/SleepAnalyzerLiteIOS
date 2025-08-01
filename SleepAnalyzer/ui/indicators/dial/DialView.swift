//
//  DialViewDolores.swift
//  SleepAnalyzer
//
//  Created by Dolores(chatGPT) on 15.05.25.
//

import SwiftUI

struct DialView<Content: View>: View {
    
    var isActive: Bool
    var markerRadius: CGFloat = 7
    var markerColor: Color = Color.yellow
    var tickRadius: CGFloat = 6
    var timeMarkerColor: Color = Color.red
    var constructionColor: Color = Color.blue.opacity(0.7)
    
    @ViewBuilder var content: () -> Content
    
    private let startTime: Date = Date()
        
    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let outerRadius = size / 2 * 0.92
            let innerRadius = size / 2 * 0.75
            
            TimelineView(.animation(minimumInterval: 1.0, paused: false)) { time in
                ZStack {
                    // Outer tick ring
                    Circle()
                        .stroke(constructionColor, lineWidth: 1)
                        .position(center)
                    
                    // Current time
                    let currentHourAngle = hoursToAngle(time.date)
                    Circle()
                        .fill(Color.red)
                        .frame(height: markerRadius)
                        .position(
                            x: center.x + outerRadius * CGFloat(cos(currentHourAngle.radians)),
                            y: center.y + outerRadius * CGFloat(sin(currentHourAngle.radians))
                        )
                    
                    // 12 - 4 circular ticks
                    ForEach(0..<12) { i in
                        let angle = Angle.degrees(Double(i) * 30)
                        let tickRadius: CGFloat = 6
                        if i % 3 != 0 {
                            Circle()
                                .fill(constructionColor)
                                .frame(width: tickRadius, height: tickRadius)
                                .position(
                                    x: center.x + outerRadius * CGFloat(cos(angle.radians)),
                                    y: center.y + outerRadius * CGFloat(sin(angle.radians))
                                )
                        }
                    }
                    
                    // Inner dotted circle (marker path)
                    Circle()
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [3]))
                        .foregroundColor(constructionColor)
                        .frame(width: innerRadius * 2, height: innerRadius * 2)
                        .position(center)
                    
                    // Hour numbers (12, 3, 6, 9)
                    Group {
                        Text("12").position(x: center.x, y: center.y - outerRadius)
                        Text("3").position(x: center.x + outerRadius, y: center.y)
                        Text("6").position(x: center.x, y: center.y + outerRadius)
                        Text("9").position(x: center.x - outerRadius, y: center.y)
                    }
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    
                    // Yellow marker
                    if isActive {
                        // Current seconds
                        let currentSecondAngle = secondsToAngle(time.date)
                        Circle()
                            .fill(markerColor)
                            .frame(height: markerRadius)
                            .position(
                                x: center.x + innerRadius * CGFloat(cos(currentSecondAngle.radians)),
                                y: center.y + innerRadius * CGFloat(sin(currentSecondAngle.radians))
                            )
                    }

                    // Content inside dial
                    content()
                }
            }
        }
    }
    
    private func secondsToAngle(_ time: Date) -> Angle {
        let seconds = Calendar.current.component(.second, from: time)
        return Angle(degrees: Double(seconds * 6) - 90)
    }
    
    private func hoursToAngle(_ time: Date) -> Angle {
        let currentTime = time
        let hour = Calendar.current.component(.hour, from: currentTime) % 12
        let minute = Calendar.current.component(.minute, from: currentTime)
        let degree = Double(hour) * 30 + Double(minute) / 2
        return Angle(degrees: degree - 90)
    }
}

struct DailViewContentView: View {
    let start = Date()
    
    var body: some View {
        VStack {
            DialView(
                isActive: true,
            ) {
                Text("hallo world")
            }
            .frame(height: .infinity)
        }
        .padding()
    }
}

struct DialView_Previews: PreviewProvider {
    static var previews: some View {
        DailViewContentView()
    }
}
