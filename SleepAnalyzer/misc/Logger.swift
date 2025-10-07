//
//  Logger.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 28.04.25.
//

import Foundation

final class Logger {
    enum Level: Int {
        case verbose
        case debug
        case info
        case warning
        case error
    }
    
    class func v(_ message: String) {
        Log.shared.log(message, .verbose)
    }

    class func d(_ message: String) {
        Log.shared.log(message, .debug)
    }

    class func i(_ message: String) {
        Log.shared.log(message, .info)
    }

    class func w(_ message: String) {
        Log.shared.log(message, .warning)
    }

    class func e(_ message: String) {
        Log.shared.log(message, .error)
    }
    
    class func setLevel(_ level: Logger.Level) {
        Log.shared.logLevel = level
    }
    
    private class Log {
        
        var logLevel: Logger.Level = .info
        
        static let shared = Log()
        
        func log(_ message: String, _ logLevel: Logger.Level) {
            #if DEBUG
            if let extendedLogMessage = logFormatter.format(message, logLevel) {
                print(extendedLogMessage)
            }
            #endif
        }
        
        private init() {}
        
        private let logFormatter: LogFormatter = .init()
        
        private class LogFormatter {
            
            lazy var dateFormator: DateFormatter = {
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm:ss.SSS"
                return formatter
            }()

            func format(_ message: String, _ logLevel: Logger.Level) -> String? {

                let logPrefix: String
                switch logLevel {
                case .error: logPrefix = "❌ err:"
                case .warning: logPrefix = "⚠️ warn:"
                case .info: logPrefix = "🧪 info:"
                case .debug: logPrefix = "✅ debug:"
                default: logPrefix = "🔹 verb:"
                }
                
                if Log.shared.logLevel.rawValue <= logLevel.rawValue {
                    return String(format: "%@ %@ %@", dateFormator.string(from: Date()), logPrefix, message)
                }
                else {
                    return nil
                }
            }
        }
    }
}

