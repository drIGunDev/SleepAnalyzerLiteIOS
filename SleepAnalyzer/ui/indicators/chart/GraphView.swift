//
//  GraphView.swift
//  SleepAnalyzer
//
//  Created by Claude(Anthropic) on 05.05.25.
//

import SwiftUI

// MARK: - Main Graph View

struct GraphView: View {
    
    struct Configuration {
        var lineColor: Color = .red
        var lineWidth: CGFloat = 1.5
        var showGrid: Bool = true
        var xGridCount: Int = 4
        var yGridCount: Int = 4
        var xGridAxisCount: Int = 4
        var yGridAxisCount: Int = 4
        var xGap: CGFloat = 20
        var yGap: CGFloat = 20
        var showXAxisTitle: Bool = true
        var showYAxisTitle: Bool = true
        var gridColor: Color = .graphGrid
        var textColor: Color = .graphText
    }
    
    @Binding var viewModel: any GraphViewModel
    
    @State private var viewSize: CGSize = .zero
    @State private var isDragging = false
    @State private var isPinching = false
    @State private var lastZoomScale: CGFloat = 1.0
    @State private var lastDragValue: CGFloat = 0.0
    
    private let cofiguration: Configuration
    private let xLabelProvider: (Double) -> (String, Font)
    private let yLabelProvider: (Double) -> (String, Font)
    private let xAxisTitle: String
    
    init(
        viewModel: Binding<any GraphViewModel>,
        configuration: Configuration = .init(),
        xLabelProvider: @escaping (Double) -> (String, Font) = { (String(format: "%.1f", $0), Font.system(size: 13)) },
        yLabelProvider: @escaping (Double) -> (String, Font) = { (String(format: "%.0f", $0), Font.system(size: 13)) },
        xAxisTitle: String = ""
    ) {
        self._viewModel = viewModel
        self.cofiguration = configuration
        self.xLabelProvider = xLabelProvider
        self.yLabelProvider = yLabelProvider
        self.xAxisTitle = xAxisTitle
        
        self.viewModel.setGaps(x: configuration.xGap, y: configuration.yGap)
        self.viewModel.showGrid(cofiguration.showGrid)
        self.viewModel.showXAxisTitle(cofiguration.showXAxisTitle)
        self.viewModel.showYAxisTitle(cofiguration.showYAxisTitle)
    }
    
    var body: some View {
        GeometryReader { geometry in
            if !viewModel.isEmpty() {
                ZStack {
                    Color(.systemBackground).opacity(0.01) // Nearly transparent for gesture detection
                    buildGraph().id("\(viewModel.scale)-\(viewModel.offset)")
                }
                .applyDragGesture(
                    isDragging: $isDragging,
                    lastDragValue: $lastDragValue,
                    geometry: geometry,
                    viewModel: viewModel
                )
                .applyZoomGesture(
                    isPinching: $isPinching,
                    lastZoomScale: $lastZoomScale,
                    viewModel: viewModel,
                    viewWidth: geometry.size.width - viewModel.gapX
                )
                .applyDoubleTapReset(viewModel: viewModel)
                .onAppear { viewSize = geometry.size }
                .onChange(of: geometry.size) { _, newSize in viewSize = newSize }
            }
        }
    }
}

// MARK: - Canvas Component

private extension GraphView {
    private func renderGrid(context: GraphicsContext, size: CGSize) {
        if cofiguration.showGrid  {
            gridLines(context: context, size: size)
        }
        if cofiguration.showXAxisTitle {
            xAxisLabel(context: context, size: size)
        }
        if cofiguration.showYAxisTitle {
            yAxisLabel(context: context, size: size)
        }
    }
    
    func buildGraph() -> some View {
        Canvas (rendersAsynchronously: true) { context, size in
            let slotsKeys = viewModel.getSlotKeys()
            for (index, slotIndex) in slotsKeys.enumerated() {
                var context = context
                
                viewModel.setCurrentSlot(forKey: slotIndex)
                
                let isAxisLabel = viewModel.isAxisLabeling(slotIndex)
                
                if viewModel.isSlotsBounded {
                    if index == 0 {
                        renderGrid(context: context, size: size)
                    }
                }
                else {
                    if isAxisLabel {
                        renderGrid(context: context, size: size)
                    }
                }
                
                // Apply clipping path
                let clipRect = CGRect(x: viewModel.gapX, y: 0, width: size.width - viewModel.gapX, height: size.height - viewModel.gapY)
                let clipPath = Path(clipRect)
                context.clip(to: clipPath)
                
                let fillColor = viewModel.getFillColor(forKey: slotIndex)
                let fillPath = fillColor != nil
                
                if fillPath {
                    drawPath(context: context, size: size, slotIndex: slotIndex, fillColor: fillColor)
                }
                drawPath(context: context, size: size, slotIndex: slotIndex)
                
                if index == 0 {
                    context.stroke(clipPath, with: .color(cofiguration.gridColor), lineWidth: 1)
                }
            }
        }
    }
    
    func drawPath(context: GraphicsContext, size: CGSize, slotIndex: Int, fillColor: Color? = nil) {
        let visiblePoints = viewModel.points
        guard visiblePoints.count > 1 else { return }
        
        let w = size.width - viewModel.gapX
        let h = size.height - viewModel.gapY
       
        var path = Path()
        
        let fillPath = fillColor != nil
        if fillPath {
            let startPoint = visiblePoints[0]
            let startX = viewModel.toViewX(startPoint.x, viewWidth: w)
            let startY = viewModel.toViewY(0, viewHeight: h)
            path.move(to: CGPoint(x: startX, y: startY))
            
            let y = viewModel.toViewY(startPoint.y, viewHeight: h)
            path.addLine(to: CGPoint(x: startX, y: y))
        }
        else {
            let startPoint = visiblePoints[0]
           
            let startX = viewModel.toViewX(startPoint.x, viewWidth: w)
            let startY = viewModel.toViewY(startPoint.y, viewHeight: h)
            
            path.move(to: CGPoint(x: startX, y: startY))
        }
        
        for i in 1..<visiblePoints.count {
            let point = visiblePoints[i]
            let x = viewModel.toViewX(point.x, viewWidth: w)
            let y = viewModel.toViewY(point.y, viewHeight: h)
            path.addLine(to: CGPoint(x: x, y: y))
            
            if fillPath && i == visiblePoints.count - 1 {
                path.addLine(to: CGPoint(x: x, y: viewModel.toViewY(0, viewHeight: h)))
                path.closeSubpath()
            }
        }
        
        let color = viewModel.getColor(forKey: slotIndex, defColor: cofiguration.lineColor)
        if fillPath {
            context.fill(path, with: .color(fillColor!))
        }
        else {
            context.stroke(path, with: .color(color), lineWidth: cofiguration.lineWidth)
        }
    }
    
    func xAxisLabel(context: GraphicsContext, size: CGSize) {
        let dx = (size.width - viewModel.gapX) / CGFloat(cofiguration.xGridAxisCount)
        for i in 0..<cofiguration.xGridAxisCount + 1 {
            let proportion = Double(i) / Double(cofiguration.xGridAxisCount)
            let adjustedWidth = size.width - viewModel.gapX
            let valueX = viewModel.toDataX(proportion * adjustedWidth, viewWidth: adjustedWidth)
            
            let (labelText, font) = xLabelProvider(valueX)
            let text = Text("\(labelText)")
                .font(font)
                .foregroundColor(cofiguration.textColor)
            let resolvedText = context.resolve(text)
            
            let position = CGPoint(x: CGFloat(i) * dx  + viewModel.gapX,
                                   y: size.height - viewModel.gapY / 2)
            if i == 0 {
                context.draw(resolvedText, at: position, anchor: .leading)
            }
            else if i == cofiguration.xGridAxisCount {
                context.draw(resolvedText, at: position, anchor: .trailing)
            }
            else {
                context.draw(resolvedText, at: position, anchor: .center)
            }
        }
    }
    
    func yAxisLabel(context: GraphicsContext, size: CGSize) {
        let dy = (size.height - viewModel.gapY) / CGFloat(cofiguration.yGridAxisCount)
        for i in 0..<cofiguration.yGridAxisCount + 1 {
            let valueY = viewModel.maxY - (Double(i) / Double(cofiguration.yGridAxisCount)) * viewModel.dataHeight
            
            let (labelText, font) = yLabelProvider(valueY)
            let text = Text("\(labelText)")
                .font(font)
                .foregroundColor(cofiguration.textColor)
            let resolvedText = context.resolve(text)
            
            let position = CGPoint(x: viewModel.gapX - 5,
                                   y: CGFloat(i) * dy )
            if i == 0 {
                context.draw(resolvedText, at: position, anchor: .topTrailing)
            }
            else if i == cofiguration.yGridAxisCount {
                context.draw(resolvedText, at: position, anchor: .bottomTrailing)
            }
            else {
                context.draw(resolvedText, at: position, anchor: .trailing)
            }
        }
    }
    
    func gridLines(context: GraphicsContext, size: CGSize) {
        let drawRect = CGRect(x: viewModel.gapX, y: 0, width: size.width - viewModel.gapX, height: size.height - viewModel.gapY)
        
        // Vertical Grid
        if cofiguration.xGridCount > 0 {
            var linePath = Path()
            for i in 1..<cofiguration.xGridCount {
                let xPos = CGFloat(i) * drawRect.width / CGFloat(cofiguration.xGridCount) + viewModel.gapX
                
                linePath.move(to: CGPoint(x: xPos, y: 0))
                linePath.addLine(to: CGPoint(x: xPos, y: drawRect.height))
            }
            context.stroke(linePath, with: .color(cofiguration.gridColor), lineWidth: 1)
        }
        
        // Horizon Grid
        if cofiguration.yGridCount > 0 {
            var linePath = Path()
            for i in 1..<cofiguration.yGridCount {
                let yPos = CGFloat(i) * drawRect.height / CGFloat(cofiguration.yGridCount)
                linePath.move(to: CGPoint(x: viewModel.gapX, y: yPos))
                linePath.addLine(to: CGPoint(x: drawRect.width + viewModel.gapX, y: yPos))
            }
            context.stroke(linePath, with: .color(cofiguration.gridColor), lineWidth: 1)
        }
        
        let rectanglePath = Path(drawRect)
        context.stroke(rectanglePath, with: .color(cofiguration.gridColor), lineWidth: 1)
    }
}

// MARK: - Gesture Extensions

private extension View {
    
    func applyDragGesture(
        isDragging: Binding<Bool>,
        lastDragValue: Binding<CGFloat>,
        geometry: GeometryProxy,
        viewModel: any GraphViewModel,
    ) -> some View {
        self.gesture(
            DragGesture()
                .onChanged { gesture in
                    if !isDragging.wrappedValue {
                        // First detection of drag - reset tracking
                        isDragging.wrappedValue = true
                        lastDragValue.wrappedValue = 0
                    }
                    
                    // Get current translation
                    let currentTranslation = gesture.translation.width
                    
                    // Calculate delta (change since last update)
                    let delta = currentTranslation - lastDragValue.wrappedValue
                    
                    // Calculate max offset based on scale
                    let maxOffset = max(0, (geometry.size.width - viewModel.gapX) * viewModel.scale - (geometry.size.width - viewModel.gapX))
                    
                    // Update offset with constraints
                    viewModel.offset = max(0, min(viewModel.offset - delta, maxOffset))
                    
                    // Save current value for next comparison
                    lastDragValue.wrappedValue = currentTranslation
                }
                .onEnded { _ in
                    isDragging.wrappedValue = false
                }
        )
    }
    
    func applyZoomGesture(
        isPinching: Binding<Bool>,
        lastZoomScale: Binding<CGFloat>,
        viewModel: any GraphViewModel,
        viewWidth: CGFloat
    ) -> some View {
        self.gesture(
            MagnificationGesture()
                .onChanged { value in
                    isPinching.wrappedValue = true
                    
                    // Calculate center point of view in data coordinates
                    let center = viewWidth / 2
                    let centerDataX = viewModel.toDataX(center, viewWidth: viewWidth)
                    
                    // Calculate the incremental change in scale
                    let delta = value / lastZoomScale.wrappedValue
                    lastZoomScale.wrappedValue = value
                    
                    // Limit zoom with smoother constraints
                    let newScale = min(max(viewModel.scale * delta, 1.0), 20.0)
                    
                    // Only update if scale actually changed
                    if abs(newScale - viewModel.scale) > 0.01 {
                        viewModel.scale = newScale
                        
                        // Adjust offset to keep the center point stable
                        let newCenterViewX = viewModel.toViewX(centerDataX, viewWidth: viewWidth) - viewModel.gapX
                        let offsetAdjustment = newCenterViewX - center
                        viewModel.offset += offsetAdjustment
                    }
                }
                .onEnded { _ in
                    isPinching.wrappedValue = false
                    lastZoomScale.wrappedValue = 1.0
                }
        )
    }
    
    func applyDoubleTapReset(viewModel: any GraphViewModel) -> some View {
        self.onTapGesture(count: 2) {
            withAnimation(.easeInOut(duration: 0.5)) {
                viewModel.resetView()
            }
        }
    }
}

// MARK: - Tests

struct GraphViewTestContentViewModel: View {
    @State private var viewModel: any GraphViewModel = GraphViewModelImpl.init()
    
    init () {
        viewModel.setPoints(forKey: 0, points: Self.generateHeartRateData(), isAxisLabel: true, color: Color.green, fillColor: nil, forcedSetCurrentSlot: false)
        viewModel.setPoints(forKey: 1, points: Self.generateHeartRateData(), isAxisLabel: false, color: Color.red.opacity(0.5), fillColor: nil, forcedSetCurrentSlot: false)
    }
    
    var body: some View {
        Group {
            GraphView(
                viewModel: $viewModel,
                configuration: GraphView.Configuration(
                    xGridAxisCount: 3,
                    yGridAxisCount: 4,
                    xGap: 25,
                    yGap: 25
                ),
                xLabelProvider: { value in
                    let hours = Int(value / 3600)
                    let minutes = Int((value.truncatingRemainder(dividingBy: 3600)) / 60)
                    return ("\(hours)h.\(minutes)m.", .system(size: 11))
                },
                yLabelProvider: { ("\(Int($0))", .system(size: 11)) }
            )
            .padding(5)
            .background(Color.gray.opacity(0.2))
            .frame(height: 260)
        }
    }
    
    // Helper function to generate realistic heart rate data
    static func generateHeartRateData() -> [UnPoint] {
        var points: [UnPoint] = []
        let duration: Double = 6.5 * 3600 // 6.5 hours in seconds
        let baseHR: Double = 55
        
        // Generate data points every 10 seconds
        for i in stride(from: 0, to: duration, by: 10) {
            // Base heart rate
            var hr = baseHR
            
            // Add sleep cycle variations (simulate different sleep stages)
            let cyclePosition = i.truncatingRemainder(dividingBy: 90 * 60) / (90 * 60) // 90-minute sleep cycles
            
            // Deep sleep (lower HR)
            if cyclePosition < 0.3 {
                hr += 5
            }
            // REM (higher HR)
            else if cyclePosition > 0.7 {
                hr += 25
            }
            // Light sleep (medium HR)
            else {
                hr += 15
            }
            
            // Add some natural variability
            hr += Double.random(in: -3...3)
            
            // Occasional movement spikes
            if Double.random(in: 0...1) < 0.02 {
                hr += Double.random(in: 15...30)
            }
            
            points.append(UnPoint(x: i, y: hr))
        }
        
        return points
    }
}

struct GraphView_Previews: PreviewProvider {
    static var previews: some View {
        GraphViewTestContentViewModel()
    }
}

struct GraphViewTestDynamicChange: View {
    @State private var viewModel: any GraphViewModel = TestGraphViewModel.init()
    
    init() {
        viewModel.setPoints(forKey: 0, points: [], isAxisLabel: true, color: .red, fillColor: nil, forcedSetCurrentSlot: true)
    }
    
    var body: some View {
        VStack {
            GraphView(
                viewModel: $viewModel,
                configuration: GraphView.Configuration(
                    xGridAxisCount: 3,
                    yGridAxisCount: 4,
                    xGap: 30),
                xLabelProvider: { ("\(Int($0))", .system(size: 13)) },
                yLabelProvider: { ("\(Int($0))", .system(size: 13)) }
            )
            .id(viewModel.invalidatedId)
            .padding(5)
            .background(Color.gray.opacity(0.2))
            .frame(height: 260)
            
            Button("Add Point") {
                viewModel.setCurrentSlot(forKey: 0)
                (viewModel as! TestGraphViewModel).addPoint(Double.random(in: 40...120))
            }
        }
    }
}

struct GraphViewDynamicChange_Previews: PreviewProvider {
    static var previews: some View {
        GraphViewTestDynamicChange()
    }
}
