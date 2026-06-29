import SwiftUI

/// The direction of a resize handle placement.
public enum ResizeDirection: String, Sendable, CaseIterable {
    case topLeft, top, topRight
    case left, right
    case bottomLeft, bottom, bottomRight
}

/// A resize handle that users embed in their node views to enable resizing.
///
/// ```swift
/// if node.selected {
///     NodeResizer(
///         nodeId: node.id,
///         direction: .bottomRight,
///         minWidth: 100, maxWidth: 500,
///         minHeight: 50, maxHeight: 400,
///         onResize: { w, h in
///             onNodesChange?([.dimensions(id: node.id, width: w, height: h)])
///         }
///     )
/// }
/// ```
public struct NodeResizer: View {
    public var nodeId: String
    public var direction: ResizeDirection
    public var minWidth: CGFloat
    public var maxWidth: CGFloat
    public var minHeight: CGFloat
    public var maxHeight: CGFloat
    public var color: Color
    public var onResize: ((CGFloat, CGFloat) -> Void)?
    public var onResizeStart: (() -> Void)?
    public var onResizeEnd: (() -> Void)?
    public var shouldResize: ((CGFloat, CGFloat) -> Bool)?

    @State private var startSize: CGSize?

    public init(
        nodeId: String,
        direction: ResizeDirection = .bottomRight,
        minWidth: CGFloat = 50,
        maxWidth: CGFloat = 1000,
        minHeight: CGFloat = 30,
        maxHeight: CGFloat = 1000,
        color: Color = .blue,
        onResize: ((CGFloat, CGFloat) -> Void)? = nil,
        onResizeStart: (() -> Void)? = nil,
        onResizeEnd: (() -> Void)? = nil,
        shouldResize: ((CGFloat, CGFloat) -> Bool)? = nil
    ) {
        self.nodeId = nodeId
        self.direction = direction
        self.minWidth = minWidth
        self.maxWidth = maxWidth
        self.minHeight = minHeight
        self.maxHeight = maxHeight
        self.color = color
        self.onResize = onResize
        self.onResizeStart = onResizeStart
        self.onResizeEnd = onResizeEnd
        self.shouldResize = shouldResize
    }

    public var body: some View {
        GeometryReader { geo in
            Circle()
                .fill(Color.white)
                .frame(width: handleSize, height: handleSize)
                .overlay(Circle().stroke(color, lineWidth: 1.5))
                .position(handlePosition(in: geo.size))
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if startSize == nil {
                                startSize = geo.size
                                onResizeStart?()
                            }
                            guard let start = startSize else { return }
                            let delta = translationForDirection(value.translation)
                            let w = min(maxWidth, max(minWidth, start.width + delta.width))
                            let h = min(maxHeight, max(minHeight, start.height + delta.height))
                            if shouldResize?(w, h) ?? true {
                                onResize?(w, h)
                            }
                        }
                        .onEnded { _ in
                            startSize = nil
                            onResizeEnd?()
                        }
                )
        }
        .allowsHitTesting(true)
    }

    private var handleSize: CGFloat { 10 }

    private func handlePosition(in size: CGSize) -> CGPoint {
        switch direction {
        case .topLeft: return CGPoint(x: 0, y: 0)
        case .top: return CGPoint(x: size.width / 2, y: 0)
        case .topRight: return CGPoint(x: size.width, y: 0)
        case .left: return CGPoint(x: 0, y: size.height / 2)
        case .right: return CGPoint(x: size.width, y: size.height / 2)
        case .bottomLeft: return CGPoint(x: 0, y: size.height)
        case .bottom: return CGPoint(x: size.width / 2, y: size.height)
        case .bottomRight: return CGPoint(x: size.width, y: size.height)
        }
    }

    private func translationForDirection(_ translation: CGSize) -> CGSize {
        switch direction {
        case .topLeft: return CGSize(width: -translation.width, height: -translation.height)
        case .top: return CGSize(width: 0, height: -translation.height)
        case .topRight: return CGSize(width: translation.width, height: -translation.height)
        case .left: return CGSize(width: -translation.width, height: 0)
        case .right: return CGSize(width: translation.width, height: 0)
        case .bottomLeft: return CGSize(width: -translation.width, height: translation.height)
        case .bottom: return CGSize(width: 0, height: translation.height)
        case .bottomRight: return CGSize(width: translation.width, height: translation.height)
        }
    }
}
