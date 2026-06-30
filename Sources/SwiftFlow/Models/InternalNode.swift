import Foundation
import SwiftUI

/// An internal representation of a node with computed layout properties.
///
/// `InternalNode` wraps a `Node` with its measured dimensions and absolute
/// position (accounting for parent hierarchy). Used for performance and
/// clean API boundaries.
public struct InternalNode<NodeData: Equatable & Sendable>: Identifiable, Equatable {
  public var id: String { node.id }

  /// The original node data.
  public var node: Node<NodeData>
  /// Absolute position on the canvas (accounting for parent offsets).
  public var absolutePosition: XYPosition
  /// Measured width from the rendered view.
  public var measuredWidth: CGFloat?
  /// Measured height from the rendered view.
  public var measuredHeight: CGFloat?

  public init(
    node: Node<NodeData>,
    absolutePosition: XYPosition = .zero,
    measuredWidth: CGFloat? = nil,
    measuredHeight: CGFloat? = nil
  ) {
    self.node = node
    self.absolutePosition = absolutePosition
    self.measuredWidth = measuredWidth
    self.measuredHeight = measuredHeight
  }

  public static func == (lhs: InternalNode, rhs: InternalNode) -> Bool {
    lhs.node == rhs.node
      && lhs.absolutePosition == rhs.absolutePosition
      && lhs.measuredWidth == rhs.measuredWidth
      && lhs.measuredHeight == rhs.measuredHeight
  }
}
