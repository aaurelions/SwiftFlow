import SwiftUI

/// A single resize handle for nodes.
///
/// Unlike `NodeResizer` which provides a full set of resize handles,
/// `NodeResizeControl` renders a single handle at a specific position.
/// Use multiple instances to create custom resize configurations.
///
/// ```swift
/// ZStack {
///     MyNodeContent()
///     NodeResizeControl(nodeId: node.id, position: .bottomRight) { w, h in
///         onNodesChange?([.dimensions(id: node.id, width: w, height: h)])
///     }
///     NodeResizeControl(nodeId: node.id, position: .right) { w, h in
///         onNodesChange?([.dimensions(id: node.id, width: w, height: h)])
///     }
/// }
/// ```
public struct NodeResizeControl: View {
    public var nodeId: String
    public var position: ResizeDirection
    public var minWidth: CGFloat
    public var maxWidth: CGFloat
    public var minHeight: CGFloat
    public var maxHeight: CGFloat
    public var color: Color
    public var handleSize: CGFloat
    public var isVisible: Bool
    public var onResize: ((CGFloat, CGFloat) -> Void)?
    public var onResizeStart: (() -> Void)?
    public var onResizeEnd: (() -> Void)?
    public var shouldResize: ((CGFloat, CGFloat) -> Bool)?

    @State private var startSize: CGSize?

    public init(
        nodeId: String,
        position: ResizeDirection = .bottomRight,
        minWidth: CGFloat = 50,
        maxWidth: CGFloat = 1000,
        minHeight: CGFloat = 30,
        maxHeight: CGFloat = 1000,
        color: Color = .blue,
        handleSize: CGFloat = 10,
        isVisible: Bool = true,
        onResize: ((CGFloat, CGFloat) -> Void)? = nil,
        onResizeStart: (() -> Void)? = nil,
        onResizeEnd: (() -> Void)? = nil,
        shouldResize: ((CGFloat, CGFloat) -> Bool)? = nil
    ) {
        self.nodeId = nodeId
        self.position = position
        self.minWidth = minWidth
        self.maxWidth = maxWidth
        self.minHeight = minHeight
        self.maxHeight = maxHeight
        self.color = color
        self.handleSize = handleSize
        self.isVisible = isVisible
        self.onResize = onResize
        self.onResizeStart = onResizeStart
        self.onResizeEnd = onResizeEnd
        self.shouldResize = shouldResize
    }

    public var body: some View {
        if isVisible {
            GeometryReader { geo in
                Circle()
                    .fill(Color.white)
                    .frame(width: handleSize, height: handleSize)
                    .overlay(Circle().stroke(color, lineWidth: 1.5))
                    .position(handlePosition(in: geo.size))
                    .cursor(cursorForDirection)
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
    }

    private func handlePosition(in size: CGSize) -> CGPoint {
        switch position {
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
        switch position {
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

    private var cursorForDirection: ResizeCursor {
        switch position {
        case .topLeft, .bottomRight: return .nwseResize
        case .topRight, .bottomLeft: return .neswResize
        case .left, .right: return .ewResize
        case .top, .bottom: return .nsResize
        }
    }
}

// MARK: - Resize Cursor

enum ResizeCursor {
    case nwseResize, neswResize, ewResize, nsResize
}

extension View {
    @ViewBuilder
    fileprivate func cursor(_ cursor: ResizeCursor) -> some View {
        #if os(macOS)
            self.onHover { hovering in
                if hovering {
                    switch cursor {
                    case .nwseResize: NSCursor.crosshair.push()
                    case .neswResize: NSCursor.crosshair.push()
                    case .ewResize: NSCursor.resizeLeftRight.push()
                    case .nsResize: NSCursor.resizeUpDown.push()
                    }
                } else {
                    NSCursor.pop()
                }
            }
        #else
            self
        #endif
    }
}
