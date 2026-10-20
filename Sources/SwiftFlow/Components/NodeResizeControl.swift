import SwiftUI

/// A single resize handle for nodes.
///
/// Renders one handle at `position` on the edge of the view it is placed in.
/// Use multiple instances to build custom resize configurations.
///
/// Like React Flow, a control inside a `SwiftFlow` canvas resizes the node
/// itself: it reports `.dimensions` changes, plus `.position` changes for
/// handles on the top or left side, through the canvas's `onNodesChange`, so
/// the opposite edge stays in place. `onResize` is a notification with the
/// new width and height; `shouldResize` can veto a step.
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
  @Environment(\.swiftFlowNodeResize) private var resizeNode

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
            // Measure in canvas coordinates: the handle moves while resizing,
            // so its local coordinate space is not stable.
            DragGesture(coordinateSpace: .named(canvasCoordinateSpace))
              .onChanged { value in
                let isStart = startSize == nil
                if isStart {
                  startSize = geo.size
                  onResizeStart?()
                }
                guard let start = startSize else { return }
                let delta = translationForDirection(value.translation)
                let w = min(maxWidth, max(minWidth, start.width + delta.width))
                let h = min(maxHeight, max(minHeight, start.height + delta.height))
                guard shouldResize?(w, h) ?? true else { return }
                resizeNode?(
                  NodeResizeEvent(
                    nodeId: nodeId, phase: isStart ? .start : .change,
                    startSize: start, size: CGSize(width: w, height: h),
                    movesLeftEdge: movesLeftEdge, movesTopEdge: movesTopEdge))
                onResize?(w, h)
              }
              .onEnded { _ in
                if let start = startSize {
                  resizeNode?(
                    NodeResizeEvent(
                      nodeId: nodeId, phase: .end, startSize: start, size: start,
                      movesLeftEdge: movesLeftEdge, movesTopEdge: movesTopEdge))
                }
                startSize = nil
                onResizeEnd?()
              }
          )
      }
      .allowsHitTesting(true)
    }
  }

  private var movesLeftEdge: Bool {
    [.topLeft, .left, .bottomLeft].contains(position)
  }

  private var movesTopEdge: Bool {
    [.topLeft, .top, .topRight].contains(position)
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

// MARK: - Canvas Integration

/// A resize step reported by `NodeResizeControl` to the enclosing canvas.
struct NodeResizeEvent {
  enum Phase { case start, change, end }

  var nodeId: String
  var phase: Phase
  /// Node size when the drag started.
  var startSize: CGSize
  /// New node size (equal to `startSize` for `.end`).
  var size: CGSize
  /// Whether the handle moves the left edge (the right edge stays fixed).
  var movesLeftEdge: Bool
  /// Whether the handle moves the top edge (the bottom edge stays fixed).
  var movesTopEdge: Bool
}

/// Position offset that keeps the edges opposite to the dragged handle fixed
/// for a node anchored at `origin`.
func resizePositionOffset(for event: NodeResizeEvent, origin: NodeOrigin) -> XYPosition {
  let dw = event.size.width - event.startSize.width
  let dh = event.size.height - event.startSize.height
  return XYPosition(
    x: event.movesLeftEdge ? -(1 - origin.x) * dw : origin.x * dw,
    y: event.movesTopEdge ? -(1 - origin.y) * dh : origin.y * dh)
}

private struct SwiftFlowNodeResizeKey: EnvironmentKey {
  // An immutable `nil`; no shared mutable state.
  nonisolated(unsafe) static let defaultValue: ((NodeResizeEvent) -> Void)? = nil
}

extension EnvironmentValues {
  /// Applies resize steps to nodes; set by `SwiftFlow`.
  var swiftFlowNodeResize: ((NodeResizeEvent) -> Void)? {
    get { self[SwiftFlowNodeResizeKey.self] }
    set { self[SwiftFlowNodeResizeKey.self] = newValue }
  }
}

// MARK: - Resize Cursor

enum ResizeCursor {
  case nwseResize, neswResize, ewResize, nsResize
}

extension View {
  @ViewBuilder
  fileprivate func cursor(_ cursor: ResizeCursor) -> some View {
    #if canImport(AppKit)
      // AppKit has no public diagonal resize cursors before macOS 15, so the
      // diagonal handles use the crosshair.
      switch cursor {
      case .nwseResize, .neswResize: hoverCursor(.crosshair)
      case .ewResize: hoverCursor(.resizeLeftRight)
      case .nsResize: hoverCursor(.resizeUpDown)
      }
    #else
      self
    #endif
  }
}
