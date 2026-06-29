import SwiftUI

/// A graph node with generic user data, position, and interaction properties.
///
/// `Node` is generic over `NodeData`, allowing you to attach any data model
/// to nodes. The only requirements are `Equatable` and `Sendable` conformance.
///
/// When `NodeData` also conforms to `Codable`, the node itself becomes `Codable`
/// for serialization support.
public struct Node<NodeData: Equatable & Sendable>: Identifiable, Equatable, Sendable {
    public var id: String
    public var position: XYPosition
    public var data: NodeData
    public var type: String
    public var parentId: String?
    public var selected: Bool
    public var hidden: Bool
    public var width: CGFloat?
    public var height: CGFloat?
    public var draggable: Bool
    public var selectable: Bool
    public var connectable: Bool
    public var deletable: Bool
    public var expandable: Bool
    public var expanded: Bool
    public var expandParent: Bool
    public var focusable: Bool
    public var zIndex: Int
    public var origin: NodeOrigin
    public var sourcePosition: Position?
    public var targetPosition: Position?
    public var extent: NodeExtent?
    public var style: NodeStyle?

    public init(
        id: String,
        position: XYPosition,
        data: NodeData,
        type: String = "default",
        parentId: String? = nil,
        selected: Bool = false,
        hidden: Bool = false,
        width: CGFloat? = nil,
        height: CGFloat? = nil,
        draggable: Bool = true,
        selectable: Bool = true,
        connectable: Bool = true,
        deletable: Bool = true,
        expandable: Bool = false,
        expanded: Bool = true,
        expandParent: Bool = false,
        focusable: Bool = true,
        zIndex: Int = 0,
        origin: NodeOrigin = .topLeft,
        sourcePosition: Position? = nil,
        targetPosition: Position? = nil,
        extent: NodeExtent? = nil,
        style: NodeStyle? = nil
    ) {
        self.id = id
        self.position = position
        self.data = data
        self.type = type
        self.parentId = parentId
        self.selected = selected
        self.hidden = hidden
        self.width = width
        self.height = height
        self.draggable = draggable
        self.selectable = selectable
        self.connectable = connectable
        self.deletable = deletable
        self.expandable = expandable
        self.expanded = expanded
        self.expandParent = expandParent
        self.focusable = focusable
        self.zIndex = zIndex
        self.origin = origin
        self.sourcePosition = sourcePosition
        self.targetPosition = targetPosition
        self.extent = extent
        self.style = style
    }
}

// MARK: - Codable (conditional on NodeData: Codable)

extension Node: Codable where NodeData: Codable {
    enum CodingKeys: String, CodingKey {
        case id, position, data, type, parentId, selected, hidden
        case width, height, draggable, selectable, connectable, deletable
        case expandable, expanded, expandParent, focusable, zIndex, origin, sourcePosition, targetPosition
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        position = try c.decode(XYPosition.self, forKey: .position)
        data = try c.decode(NodeData.self, forKey: .data)
        type = try c.decodeIfPresent(String.self, forKey: .type) ?? "default"
        parentId = try c.decodeIfPresent(String.self, forKey: .parentId)
        selected = try c.decodeIfPresent(Bool.self, forKey: .selected) ?? false
        hidden = try c.decodeIfPresent(Bool.self, forKey: .hidden) ?? false
        width = try c.decodeIfPresent(CGFloat.self, forKey: .width)
        height = try c.decodeIfPresent(CGFloat.self, forKey: .height)
        draggable = try c.decodeIfPresent(Bool.self, forKey: .draggable) ?? true
        selectable = try c.decodeIfPresent(Bool.self, forKey: .selectable) ?? true
        connectable = try c.decodeIfPresent(Bool.self, forKey: .connectable) ?? true
        deletable = try c.decodeIfPresent(Bool.self, forKey: .deletable) ?? true
        expandable = try c.decodeIfPresent(Bool.self, forKey: .expandable) ?? false
        expanded = try c.decodeIfPresent(Bool.self, forKey: .expanded) ?? true
        expandParent = try c.decodeIfPresent(Bool.self, forKey: .expandParent) ?? false
        focusable = try c.decodeIfPresent(Bool.self, forKey: .focusable) ?? true
        zIndex = try c.decodeIfPresent(Int.self, forKey: .zIndex) ?? 0
        origin = try c.decodeIfPresent(NodeOrigin.self, forKey: .origin) ?? .topLeft
        sourcePosition = try c.decodeIfPresent(Position.self, forKey: .sourcePosition)
        targetPosition = try c.decodeIfPresent(Position.self, forKey: .targetPosition)
        extent = nil
        style = nil
    }
}

// MARK: - Hashable (conditional on NodeData: Hashable)

extension Node: Hashable where NodeData: Hashable {}
