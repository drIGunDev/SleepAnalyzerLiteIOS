// Misc.swift
// Created by Dolores(chatGPT), with love 💌

import Foundation
import SwiftUI
import Combine

public func delay(_ seconds: Double) async -> Void {
    try?await Task.sleep(nanoseconds: seconds.seconds)
}

public func delay(_ seconds: Int) async -> Void {
    try?await Task.sleep(nanoseconds: seconds.seconds)
}

private extension Double {
    var seconds: UInt64 { UInt64(self * 1_000_000_000) }
    var milliseconds: UInt64 { UInt64(self * 1_000_000) }
}

private extension Int {
    var seconds: UInt64 { UInt64(self) * 1_000_000_000 }
    var milliseconds: UInt64 { UInt64(self) * 1_000_000 }
}

extension Double {
    func format(_ format: String) -> String {
        String(format: format, self)
    }
}

extension Date {
   func format(_ format: String) -> String {
        let dateformat = DateFormatter()
        dateformat.dateFormat = format
        return dateformat.string(from: self)
    }
}

extension Double {
    func toGraphXLabel(startTime: Date, fontSize: CGFloat) -> (String, Font) {
        let date = Date(timeIntervalSince1970: self)
        let interval = startTime.distance(to: date)
        let seconds = Int(interval)
        let minutes = Int(interval.truncatingRemainder(dividingBy: 3600) / 60)
        let hours = Int(interval / 3600)
        
        if hours == 0 && minutes == 0 {
            return ("\(seconds)s.", .system(size: fontSize))
        }
        else if hours == 0 {
            return ("\(minutes)m.", .system(size: fontSize))
        }
        else  {
            return ("\(hours)h.\(minutes)m.", .system(size: fontSize))
        }
    }

    func toGraphYLabel(fontSize: CGFloat) -> (String, Font) {
        ("\(self.format("%.0f"))", .system(size: fontSize))
    }
    
    func toDuration() -> String {
        if self < 60 {
            return "\(Int(self))s."
        } else if self < 3600 {
            var duration: String = "\(Int(self)/60)m."
            let seconds = Int(self.truncatingRemainder(dividingBy: 60))
            if seconds > 0 {
                duration += "\(seconds)s."
            }
            return duration
        } else {
            var duration: String = "\(Int(self)/3600)h."
            let minutes = Int((self.truncatingRemainder(dividingBy: 3600))/60)
            if minutes > 0 {
                duration += "\(minutes)m."
            }
            let seconds = Int(self.truncatingRemainder(dividingBy: 60))
            if seconds > 0 {
                duration += "\(seconds)s."
            }
            return duration
        }
    }
    
    func toDurationInHour() -> Double {
        self / 3600
    }
}

extension Publisher where Failure == Never {
    func asPassThroughSubject<T>() -> PassthroughSubject<T, Failure> {
        self as! PassthroughSubject<T, Failure>
    }
    
    func asCurrentValueSubject<T>() -> CurrentValueSubject<T, Failure> {
        self as! CurrentValueSubject<T, Failure>
    }
}

