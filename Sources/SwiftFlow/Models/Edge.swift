import SwiftUI

/// Alias that avoids the ambiguity with `SwiftUI.Edge` when the module and
/// the ``SwiftFlow`` view struct share the same name.
public typealias FlowEdge = Edge

/// The path shape used to render an edge between two nodes.
public enum EdgeType: String, Equatable, Sendable, Codable, Hashable {
  /// Smooth cubic bezier curve (default).
  case `default` = "default"
  /// Alias for `.default`.
  case bezier = "bezier"
  /// Direct straight line.
  case straight = "straight"
  /// Right-angle step path with sharp corners.
  case step = "step"
  /// Right-angle step path with rounded corners.
  case smoothstep = "smoothstep"
  /// Simple quadratic bezier curve with a single control point.
  case simplebezier = "simplebezier"
}

/// The visual style of an edge endpoint marker.
public enum MarkerType: String, Equatable, Sendable, Codable, Hashable {
  /// Open arrowhead (stroke only).
  case arrow = "arrow"
  /// Filled arrowhead (closed triangle).
  case arrowClosed = "arrowclosed"
}

/// Configuration for a marker rendered at an edge endpoint.
public struct EdgeMarker: Equatable, Sendable, Codable, Hashable {
  public var type: MarkerType
  public var width: CGFloat
  public var height: CGFloat

  public init(type: MarkerType, width: CGFloat = 12, height: CGFloat = 12) {
    self.type = type
    self.width = width
    self.height = height
  }

  /// An open arrowhead marker with default dimensions.
  public static let arrow = EdgeMarker(type: .arrow)
  /// A filled arrowhead marker with default dimensions.
  public static let arrowClosed = EdgeMarker(type: .arrowClosed)
}

/// An empty data type for edges that don't need custom data.
///
/// Use this as the `EdgeData` type parameter when you don't need to attach
/// custom data to edges:
/// ```swift
/// @State var edges: [Edge<EmptyEdgeData>] = [...]
/// ```
public struct EmptyEdgeData: Equatable, Sendable, Codable, Hashable {
  public init() {}
}

/// A connection between two nodes in the graph.
///
/// Edges connect a source node/handle to a target node/handle and support
/// multiple visual styles including different path types, labels, markers,
/// and animation.
///
/// `Edge` is generic over `EdgeData`, allowing you to attach rich structured
/// data to edges. Use `EmptyEdgeData` when no custom data is needed.
///
/// ```swift
/// // Edge without custom data
/// let edge = Edge<EmptyEdgeData>(id: "e1", source: "1", target: "2")
///
/// // Edge with custom data
/// struct FlowData: Equatable, Sendable, Codable, Hashable {
///     var weight: Double
/// }
/// let edge = Edge<FlowData>(id: "e1", source: "1", target: "2",
///                            data: FlowData(weight: 1.0))
/// ```
public struct Edge<EdgeData: Equatable & Sendable & Hashable>: Identifiable, Equatable, Sendable,
  Hashable
{
  public var id: String
  public var source: String
  public var target: String
  public var sourceHandle: String?
  public var targetHandle: String?
  public var type: EdgeType
  public var selected: Bool
  public var hidden: Bool
  public var label: String?
  public var animated: Bool
  public var markerStart: EdgeMarker?
  public var markerEnd: EdgeMarker?
  public var zIndex: Int
  public var reconnectable: Bool
  public var deletable: Bool
  public var focusable: Bool
  public var interactionWidth: CGFloat
  public var data: EdgeData?
  public var style: EdgeStyle?

  public init(
    id: String,
    source: String,
    target: String,
    sourceHandle: String? = nil,
    targetHandle: String? = nil,
    type: EdgeType = .default,
    selected: Bool = false,
    hidden: Bool = false,
    label: String? = nil,
    animated: Bool = false,
    markerStart: EdgeMarker? = nil,
    markerEnd: EdgeMarker? = nil,
    zIndex: Int = 0,
    reconnectable: Bool = false,
    deletable: Bool = true,
    focusable: Bool = true,
    interactionWidth: CGFloat = 20,
    data: EdgeData? = nil,
    style: EdgeStyle? = nil
  ) {
    self.id = id
    self.source = source
    self.target = target
    self.sourceHandle = sourceHandle
    self.targetHandle = targetHandle
    self.type = type
    self.selected = selected
    self.hidden = hidden
    self.label = label
    self.animated = animated
    self.markerStart = markerStart
    self.markerEnd = markerEnd
    self.zIndex = zIndex
    self.reconnectable = reconnectable
    self.deletable = deletable
    self.focusable = focusable
    self.interactionWidth = interactionWidth
    self.data = data
    self.style = style
  }
}

// MARK: - Codable

extension Edge: Codable where EdgeData: Codable {
  private enum CodingKeys: String, CodingKey {
    case id, source, target, sourceHandle, targetHandle, type
    case selected, hidden, label, animated
    case markerStart, markerEnd, zIndex
    case reconnectable, deletable, focusable, interactionWidth, data, style
  }

  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    id = try c.decode(String.self, forKey: .id)
    source = try c.decode(String.self, forKey: .source)
    target = try c.decode(String.self, forKey: .target)
    sourceHandle = try c.decodeIfPresent(String.self, forKey: .sourceHandle)
    targetHandle = try c.decodeIfPresent(String.self, forKey: .targetHandle)
    type = try c.decodeIfPresent(EdgeType.self, forKey: .type) ?? .default
    selected = try c.decodeIfPresent(Bool.self, forKey: .selected) ?? false
    hidden = try c.decodeIfPresent(Bool.self, forKey: .hidden) ?? false
    label = try c.decodeIfPresent(String.self, forKey: .label)
    animated = try c.decodeIfPresent(Bool.self, forKey: .animated) ?? false
    markerStart = try c.decodeIfPresent(EdgeMarker.self, forKey: .markerStart)
    markerEnd = try c.decodeIfPresent(EdgeMarker.self, forKey: .markerEnd)
    zIndex = try c.decodeIfPresent(Int.self, forKey: .zIndex) ?? 0
    reconnectable = try c.decodeIfPresent(Bool.self, forKey: .reconnectable) ?? false
    deletable = try c.decodeIfPresent(Bool.self, forKey: .deletable) ?? true
    focusable = try c.decodeIfPresent(Bool.self, forKey: .focusable) ?? true
    interactionWidth = try c.decodeIfPresent(CGFloat.self, forKey: .interactionWidth) ?? 20
    data = try c.decodeIfPresent(EdgeData.self, forKey: .data)
    style = try c.decodeIfPresent(EdgeStyle.self, forKey: .style)
  }
}
