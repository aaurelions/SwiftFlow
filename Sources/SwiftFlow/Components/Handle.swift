import SwiftUI

/// A connection handle placed inside custom node views.
///
/// Handles define the connection points where edges attach to nodes.
/// Each handle has a `type` (source or target) and a `position`: the node
/// side the handle sits on. Place the handle on that side in your node
/// layout. Edges leave and enter the handle in the direction of `position`.
///
/// ```swift
/// HStack {
///     Handle(nodeId: node.id, id: "in", type: .target, position: .left)
///     Spacer()
///     Handle(nodeId: node.id, id: "out", type: .source, position: .right)
/// }
/// ```
public struct Handle: View {
  public var nodeId: String
  public var id: String
  public var type: HandleType
  public var position: Position
  /// Fill color. `nil` uses the canvas theme's `handleColor`.
  public var color: Color?
  /// Whether connections can start or end at this handle.
  public var isConnectable: Bool

  @Environment(\.swiftFlowTheme) private var theme
  @Environment(\.swiftFlowAccessibilityConfig) private var accessibilityConfig

  public init(
    nodeId: String,
    id: String,
    type: HandleType = .source,
    position: Position,
    color: Color? = nil,
    isConnectable: Bool = true
  ) {
    self.nodeId = nodeId
    self.id = id
    self.type = type
    self.position = position
    self.color = color
    self.isConnectable = isConnectable
  }

  /// Backward-compatible initializer using `handleId` parameter name.
  @available(*, deprecated, renamed: "init(nodeId:id:type:position:color:isConnectable:)")
  public init(
    nodeId: String,
    handleId: String,
    type: HandleType = .source,
    position: Position,
    color: Color? = nil,
    isConnectable: Bool = true
  ) {
    self.init(
      nodeId: nodeId, id: handleId, type: type, position: position,
      color: color, isConnectable: isConnectable)
  }

  public var isSource: Bool { type == .source }

  public var body: some View {
    let fill = color ?? theme.handleColor
    let key = HandlePositionPreferenceKey.makeKey(nodeId: nodeId, handleId: id, type: type)
    Circle()
      .fill(fill)
      .frame(width: theme.handleSize, height: theme.handleSize)
      .overlay(Circle().stroke(theme.handleBorderColor, lineWidth: 2))
      .shadow(color: fill.opacity(0.4), radius: 2)
      .background(
        GeometryReader { geo in
          let frame = geo.frame(in: .named(canvasCoordinateSpace))
          Color.clear
            .preference(
              key: HandlePositionPreferenceKey.self,
              value: [key: CGPoint(x: frame.midX, y: frame.midY)]
            )
            .preference(key: HandleTypePreferenceKey.self, value: [key: type])
            .preference(
              key: HandleInfoPreferenceKey.self,
              value: [key: HandleInfo(position: position, isConnectable: isConnectable)]
            )
        }
      )
      .accessibilityElement()
      .accessibilityLabel(
        isSource
          ? String(
            localized: "Output handle \(id)", bundle: .module, comment: "Source handle label")
          : String(localized: "Input handle \(id)", bundle: .module, comment: "Target handle label")
      )
      .accessibilityHint(accessibilityConfig.handleAriaLabel)
  }
}

/// Name of the coordinate space of the canvas content (flow coordinates).
let canvasCoordinateSpace = "SwiftFlowCanvas"

/// Side and connectability of a rendered handle.
struct HandleInfo: Equatable {
  var position: Position
  var isConnectable: Bool
}

/// Propagates `HandleInfo` values keyed like `HandlePositionPreferenceKey`.
struct HandleInfoPreferenceKey: PreferenceKey {
  static let defaultValue: [String: HandleInfo] = [:]

  static func reduce(value: inout [String: HandleInfo], nextValue: () -> [String: HandleInfo]) {
    value.merge(nextValue()) { current, _ in current }
  }
}
