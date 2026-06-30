import SwiftUI

/// A connection handle placed inside custom node views.
///
/// Handles define the connection points where edges attach to nodes.
/// Each handle has a `type` (source or target) and a `position` that
/// determines its visual placement within the node.
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
  public var color: Color
  public var isConnectable: Bool

  public init(
    nodeId: String,
    id: String,
    type: HandleType = .source,
    position: Position,
    color: Color = .gray,
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
    color: Color = .gray,
    isConnectable: Bool = true
  ) {
    self.init(
      nodeId: nodeId, id: handleId, type: type, position: position,
      color: color, isConnectable: isConnectable)
  }

  public var isSource: Bool { type == .source }

  public var body: some View {
    Circle()
      .fill(color)
      .frame(width: 12, height: 12)
      .overlay(Circle().stroke(Color.white, lineWidth: 2))
      .shadow(color: color.opacity(0.4), radius: 2)
      .background(
        GeometryReader { geo in
          let frame = geo.frame(in: .named("SwiftFlowCanvas"))
          let key = HandlePositionPreferenceKey.makeKey(nodeId: nodeId, handleId: id, type: type)
          Color.clear
            .preference(
              key: HandlePositionPreferenceKey.self,
              value: [key: CGPoint(x: frame.midX, y: frame.midY)]
            )
            .preference(
              key: HandleTypePreferenceKey.self,
              value: [key: type]
            )
        }
      )
      .accessibilityElement()
      .accessibilityLabel("\(isSource ? "Output" : "Input") handle \(id)")
      .accessibilityHint("Drag to create a connection")
  }
}
