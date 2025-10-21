//
//  MemmoryWatcher.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 21.10.25.
//

import Foundation
import Combine

@Observable final class MemoryWatcher {
    var usedMemory: UInt64 = 0
    
    private let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    private var cancellables: Set<AnyCancellable> = []
    
    init() {
        timer.sink { [weak self] _ in
            guard let self else { return }
            self.usedMemory = computeMemory()
        }
        .store(in: &cancellables)
    }
    
    private func computeMemory() -> UInt64 {
        var taskInfo = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        guard kerr == KERN_SUCCESS else {
            Logger.e("Error with task_info(): \(String(cString: mach_error_string(kerr), encoding: String.Encoding.ascii) ?? "unknown error")")
            return 0
        }
        
        let usedMegabytes = taskInfo.resident_size/(1024 * 1024)
        return usedMegabytes
    }
}
