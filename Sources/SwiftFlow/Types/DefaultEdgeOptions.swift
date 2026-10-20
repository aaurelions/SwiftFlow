import Foundation

/// Default properties applied to edges, mirroring React Flow's `defaultEdgeOptions`.
///
/// React Flow merges these options under each edge (`{ ...defaultEdgeOptions, ...edge }`).
/// Because `Edge` properties are non-optional in Swift, a default fills a
/// property only while the edge still has its initializer default:
/// `type == .default`, `animated == false`, and `markerStart`/`markerEnd == nil`.
///
/// `SwiftFlow` applies these options when rendering edges, and
/// `addEdge(_:edges:defaults:)` applies them to the edge it creates.
public struct DefaultEdgeOptions: Equatable, Sendable {
  public var type: EdgeType
  public var animated: Bool
  public var markerStart: EdgeMarker?
  public var markerEnd: EdgeMarker?

  public init(
    type: EdgeType = .default,
    animated: Bool = false,
    markerStart: EdgeMarker? = nil,
    markerEnd: EdgeMarker? = nil
  ) {
    self.type = type
    self.animated = animated
    self.markerStart = markerStart
    self.markerEnd = markerEnd
  }

  /// Returns `edge` with these defaults filling its unset properties.
  func applied<EdgeData>(to edge: Edge<EdgeData>) -> Edge<EdgeData> {
    var result = edge
    if result.type == .default { result.type = type }
    result.animated = result.animated || animated
    result.markerStart = result.markerStart ?? markerStart
    result.markerEnd = result.markerEnd ?? markerEnd
    return result
  }
}
