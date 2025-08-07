//
//  GraphViewModel.swift
//  SleepAnalyzer
//
//  Created by Claude(Anthropic) on 10.06.25.
//

import SwiftUI
import SwiftInjectLite

protocol GraphViewModel: ObservableObject {
    var invalidatedId: String { get }
    
    @ObservationIgnored var points: [UnPoint] { get set }
    
    // View state
    var scale: Double { get set }
    var offset: Double { get set }
    
    // Boundaries
    @ObservationIgnored var minX: Double { get set }
    @ObservationIgnored var maxX: Double { get set }
    @ObservationIgnored var minY: Double { get set }
    @ObservationIgnored var maxY: Double { get set }
    
    // Calculated from data
    @ObservationIgnored var dataWidth: Double { get set }
    @ObservationIgnored var dataHeight: Double { get set }
    
    @ObservationIgnored var gapX: CGFloat { get set }
    @ObservationIgnored var gapY: CGFloat { get set }
    
    @ObservationIgnored var originalGapX: CGFloat { get }
    @ObservationIgnored var originalGapY: CGFloat { get }

    @ObservationIgnored var isSlotsBounded: Bool { get set }
    
    func toViewX(_ dataX: Double, viewWidth: Double) -> Double
    func toViewY(_ dataY: Double, viewHeight: Double) -> Double
    func toDataX(_ viewX: Double, viewWidth: Double) -> Double
    func showGrid(_ show: Bool)
    func showXAxisTitle(_ show: Bool)
    func showYAxisTitle(_ show: Bool)
    func setGaps(x gapX: CGFloat, y gapY: CGFloat)

    // slots management
    func getSlotKeys() -> [Int]
    func setCurrentSlot(forKey index: Int)
    func removeSlot(forKey index: Int)
    func removeSlots()
    func isEmpty() -> Bool
    func isAxisLabeling(_ index: Int) -> Bool
    func getColor(forKey index: Int?, defColor: Color) -> Color
    func getFillColor(forKey index: Int?) -> Color?
    func addPoint(_ point: UnPoint)
    func setPoints(
        forKey index: Int,
        points: [UnPoint],
        isAxisLabel: Bool,
        color: Color,
        fillColor: Color?,
        forcedSetCurrentSlot: Bool
    )
    func scaleX(forKey index: Int, minValue: Double, maxValue: Double)
    func setAutoScaleX(forKey index: Int)
    func resetView()
}

@Observable class GraphViewModelImpl: GraphViewModel {
    var invalidatedId: String = UUID().uuidString
    
    // Data points to display
    @ObservationIgnored var points: [UnPoint] = []
    
    // View state
    var scale: Double = 1.0
    var offset: Double = 0.0
    
    // Boundaries
    @ObservationIgnored var minX: Double = 0.0
    @ObservationIgnored var maxX: Double = 1.0
    @ObservationIgnored var minY: Double = 0.0
    @ObservationIgnored var maxY: Double = 1.0
    
    // Calculated from data
    @ObservationIgnored var dataWidth: Double = 0.0
    @ObservationIgnored var dataHeight: Double = 0.0
    
    @ObservationIgnored var gapX: CGFloat = 20
    @ObservationIgnored var gapY: CGFloat = 20

    @ObservationIgnored private(set) var originalGapX: CGFloat = 20
    @ObservationIgnored private(set) var originalGapY: CGFloat = 20
    
    @ObservationIgnored var isSlotsBounded: Bool = false
    
    @ObservationIgnored private var dataSlots: DataSlots

    init(gapX: CGFloat = 20, gapY: CGFloat = 20) {
        self.dataSlots = .init()
        self.setGaps(x: gapX, y: gapY)
    }
    
    func invalidateGraph() {
        invalidatedId = UUID().uuidString
    }
    
    func setGaps(x gapX: CGFloat, y gapY: CGFloat) {
        self.gapX = gapX
        self.originalGapX = gapX
        self.gapY = gapY
        self.originalGapY = gapY
    }
    
    func scaleX(forKey index: Int, minValue: Double, maxValue: Double) {
        dataSlots.scaleX(forKey: index, minValue: minValue, maxValue: maxValue)
    }
    
    func setAutoScaleX(forKey index: Int) {
        dataSlots.setAutoscale(forKey: index)
    }
    
    // Convert data x to view x
    func toViewX(_ dataX: Double, viewWidth: Double) -> Double {
        let normalizedX = (dataX - minX) / dataWidth
        return normalizedX * viewWidth * scale - offset + gapX
    }
    
    // Convert data y to view y
    func toViewY(_ dataY: Double, viewHeight: Double) -> Double {
        let normalizedY = 1.0 - ((dataY - minY) / dataHeight)
        return normalizedY * viewHeight
    }
    
    // Convert screen x position back to data x
    func toDataX(_ viewX: Double, viewWidth: Double) -> Double {
        let normalizedX = (viewX + offset) / (viewWidth * scale)
        return normalizedX * dataWidth + minX
    }
    
    // Reset zoom and position
    func resetView() {
        scale = 1.0
        offset = 0.0
    }
    
    func showGrid(_ show: Bool) {
        self.gapX = show ? self.originalGapX : 0
        self.gapY = show ? self.originalGapY : 0
    }
    
    func showXAxisTitle(_ show: Bool) {
        self.gapY = show ? originalGapY : 0
    }
    
    func showYAxisTitle(_ show: Bool) {
        self.gapX = show ? originalGapX : 0
    }
    
    func isEmpty() -> Bool {
        dataSlots.isEmpty
    }
    
    func isAxisLabeling(_ index: Int) -> Bool {
        dataSlots.isAxisLabel(index)
    }
    
    func setCurrentSlot(forKey index: Int) {
        dataSlots.currentSlotIndex = index
        points = dataSlots.getPoints(forKey: index)
        calculateBoundaries()
    }
    
    func removeSlot(forKey index: Int) {
        dataSlots.remove(forKey: index)
        
        invalidateGraph()
    }
    
    func removeSlots() {
        dataSlots.removeAll()
        
        invalidateGraph()
    }
    
    func getColor(forKey index: Int?, defColor: Color) -> Color {
        dataSlots.getColor(forKey: index, defColor: defColor)
    }
    
    func getFillColor(forKey index: Int?) -> Color? {
        dataSlots.getFillColor(forKey: index)
    }
    
    func getSlotKeys() -> [Int] {
        dataSlots.getSlotKeys()
    }

    func addPoint(_ point: UnPoint) {
        dataSlots.addPoint(point)
        points = dataSlots.getPoints()
        calculateBoundaries()
        
        invalidateGraph()
    }
    
    func setPoints(
        forKey index: Int,
        points: [UnPoint],
        isAxisLabel: Bool,
        color: Color,
        fillColor: Color?,
        forcedSetCurrentSlot: Bool
    ) {
        dataSlots.setPoints(forKey: index, points: points, isAxisLabel: isAxisLabel, color: color, fillColor: fillColor)
        
        if forcedSetCurrentSlot {
            setCurrentSlot(forKey: index)
        }
        
        invalidateGraph()
    }
    
    private func calculateBoundaries() {
        let boundaries = isSlotsBounded ? dataSlots.boundedBoundaries() : dataSlots.boundaries(forKey: dataSlots.currentSlotIndex)
        guard let boundaries else { return }
        
        maxX = boundaries.maxX
        minX = boundaries.minX
        maxY = boundaries.maxY
        minY = boundaries.minY
        dataWidth = maxX - minX
        dataHeight = maxY - minY
    }

    private func getFirstKey() -> Int {
        dataSlots.getFirstKey()
    }
}

private struct DataSlots {
    struct Slot {
        var color: Color?
        var fillColor: Color? = nil
        var isAxisLabel: Bool?
        var isAutoscale = true
        var maxY: Double? = nil
        var minY: Double? = nil
        
        var points: [UnPoint]
    }

    var isEmpty: Bool { self.slotsMap.isEmpty }
    var count: Int { self.slotsMap.count }
    
    var currentSlotIndex: Int = 0
    
    private var slotsMap: [Int: Slot] = [:]

    typealias Boundaries = (minX: Double, maxX: Double, minY: Double, maxY: Double)
    func boundaries(forKey index: Int) -> Boundaries? {
        guard let slot = self.slotsMap[index] else { return nil }
        
        let points = slot.points
        guard points.count > 0 else { return nil }

        let minX = points.min(by: { $0.x < $1.x })?.x ?? 0
        let maxX = points.max(by: { $0.x < $1.x })?.x ?? 1
        
        let minY: Double
        let maxY: Double
        if slot.isAutoscale {
            minY = points.min(by: { $0.y < $1.y })?.y ?? 0
            maxY = points.max(by: { $0.y < $1.y })?.y ?? 1
        }
        else {
            minY = slot.minY ?? 0
            maxY = slot.maxY ?? 1
        }
    
        return (minX: minX, maxX: maxX, minY: minY, maxY: maxY)
    }
    
    func boundedBoundaries() -> Boundaries? {
        var minX: Double = 1
        var maxX: Double = 0
        var minY: Double = 1
        var maxY: Double = 0
        
        let indexes = self.slotsMap.keys
        indexes.forEach { index in
            if let bounds = self.boundaries(forKey: index) {
                minX = bounds.minX
                maxX = bounds.maxX
                minY = Swift.min(minY, bounds.minY)
                maxY = Swift.max(maxY, bounds.maxY)
            }
        }
        return (minX: minX, maxX: maxX, minY: minY, maxY: maxY)
    }
    
    func getColor(forKey index: Int? = nil, defColor: Color = .black) -> Color {
        let index = index ?? getFirstKey()
        return self.slotsMap[index]?.color ?? defColor
    }
    
    func getFillColor(forKey index: Int? = nil, defColor: Color = .gray) -> Color? {
        let index = index ?? getFirstKey()
        return self.slotsMap[index]?.fillColor
    }
    
    func getPoints(forKey index: Int? = nil) -> [UnPoint] {
        let index = index ?? getFirstKey()
        return self.slotsMap[index]?.points ?? []
    }
    
    func isAxisLabel(_ index: Int? = nil) -> Bool {
        let index = index ?? getFirstKey()
        return self.slotsMap[index]?.isAxisLabel ?? false
    }
    
    func getSlotKeys() -> [Int] {
        Array(self.slotsMap.keys).sorted()
    }
    
    func getCurrentSlot() -> Slot? {
        self.slotsMap[currentSlotIndex]
    }
    
    func getFirstKey() -> Int {
        guard !isEmpty else { return 0 }
        return getSlotKeys().first ?? 0
    }
    
    mutating func setPoints(forKey index: Int? = nil,
                            points: [UnPoint],
                            isAxisLabel: Bool = false,
                            color: Color = .black,
                            fillColor: Color? = nil) {
        let slot = Slot(color: color, fillColor: fillColor, isAxisLabel: isAxisLabel, points: points)
        let index = index ?? getFirstKey()
        self.slotsMap[index] = slot
    }
    
    mutating func addPoint(_ point: UnPoint,
                           forKey index: Int? = nil) {
        let index = index ?? getFirstKey()
        if var points = self.slotsMap[index]?.points {
            points.append(point)
            self.slotsMap[index]?.points = points
        }
        else {
            self.slotsMap[index]?.points = [point]
        }
    }
    
    mutating func remove(forKey index: Int) {
        self.slotsMap[index] = nil
    }
    
    mutating func scaleX(forKey index: Int, minValue: Double, maxValue: Double) {
        self.slotsMap[index]?.isAutoscale = false
        self.slotsMap[index]?.minY = minValue
        self.slotsMap[index]?.maxY = maxValue
    }
    
    mutating func setAutoscale(forKey index: Int) {
        self.slotsMap[index]?.isAutoscale = true
    }
    
    mutating func removeAll() {
        self.slotsMap.removeAll()
    }
}
// MARK: - DI

extension InjectionRegistry {
    var graphViewModel: any GraphViewModel { Self.instantiate(.factory) { GraphViewModelImpl.init() } }
}

final class TestGraphViewModel: GraphViewModelImpl {
    var currentX: Double = 0
    
    func toPoint(_ y: Double) -> UnPoint {
        currentX += 0.1
        return UnPoint(x: currentX, y: y)
    }
    
    func addPoint(_ y: Double) {
        addPoint(toPoint(y))
    }
}
