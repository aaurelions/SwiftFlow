import SwiftUI

/// The direction of a resize handle placement.
public enum ResizeDirection: String, Sendable, CaseIterable {
  case topLeft, top, topRight
  case left, right
  case bottomLeft, bottom, bottomRight
}

/// A resize handle that users embed in their node views to enable resizing.
///
/// `NodeResizer` renders one handle at `direction`. It is a convenience
/// wrapper around `NodeResizeControl`; use several instances for several
/// handles. Inside a canvas it resizes the node itself (see `NodeResizeControl`);
/// `onResize` reports the new width and height.
///
/// ```swift
/// if node.selected {
///     NodeResizer(
///         nodeId: node.id,
///         direction: .bottomRight,
///         minWidth: 100, maxWidth: 500,
///         minHeight: 50, maxHeight: 400
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
    NodeResizeControl(
      nodeId: nodeId, position: direction,
      minWidth: minWidth, maxWidth: maxWidth,
      minHeight: minHeight, maxHeight: maxHeight,
      color: color,
      onResize: onResize, onResizeStart: onResizeStart, onResizeEnd: onResizeEnd,
      shouldResize: shouldResize)
  }
}
