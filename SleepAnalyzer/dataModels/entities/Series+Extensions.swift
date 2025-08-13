//
//  Series+Extensions.swift
//  SleepAnalyzer
//
//  Created by Igor Gun on 13.08.25.
//

extension Array where Element == SeriesDTO {
    mutating func remove(_ series: SeriesDTO) {
        if let index = firstIndex(where: { $0.id == series.id }) {
            remove(at: index)
        }
    }
    
    func first(_ series: SeriesDTO) -> SeriesDTO? {
        first(where: { $0.id == series.id })
    }
}

extension Array where Element == UpdatableWrapper<SeriesDTO> {
    mutating func remove(_ series: Element) {
        if let index = firstIndex(where: { $0.wrappedValue.id == series.wrappedValue.id }) {
            remove(at: index)
        }
    }
}
