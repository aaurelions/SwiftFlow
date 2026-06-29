import Foundation

/// A complete graph state for serialization.
///
/// Contains all nodes, edges, and an optional viewport snapshot.
public struct SwiftFlowDocument<NodeData: Equatable & Sendable & Codable, EdgeData: Equatable & Sendable & Hashable & Codable>: Codable, Sendable {
    public var nodes: [Node<NodeData>]
    public var edges: [Edge<EdgeData>]
    public var viewport: Viewport?

    public init(nodes: [Node<NodeData>], edges: [Edge<EdgeData>], viewport: Viewport? = nil) {
        self.nodes = nodes
        self.edges = edges
        self.viewport = viewport
    }
}

// MARK: - Export

/// Encodes nodes and edges to JSON `Data`.
public func toJSON<NodeData: Codable & Equatable & Sendable, EdgeData: Equatable & Sendable & Hashable & Codable>(
    nodes: [Node<NodeData>], edges: [Edge<EdgeData>], viewport: Viewport? = nil
) throws -> Data {
    let doc = SwiftFlowDocument(nodes: nodes, edges: edges, viewport: viewport)
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    return try encoder.encode(doc)
}

/// Encodes nodes and edges to a JSON `String`.
public func toJSONString<NodeData: Codable & Equatable & Sendable, EdgeData: Equatable & Sendable & Hashable & Codable>(
    nodes: [Node<NodeData>], edges: [Edge<EdgeData>], viewport: Viewport? = nil
) throws -> String {
    let data = try toJSON(nodes: nodes, edges: edges, viewport: viewport)
    return String(data: data, encoding: .utf8) ?? ""
}

// MARK: - Import

/// Decodes a `SwiftFlowDocument` from JSON `Data`.
public func fromJSON<NodeData: Codable & Equatable & Sendable, EdgeData: Equatable & Sendable & Hashable & Codable>(
    _ data: Data
) throws -> SwiftFlowDocument<NodeData, EdgeData> {
    try JSONDecoder().decode(SwiftFlowDocument<NodeData, EdgeData>.self, from: data)
}

/// Decodes a `SwiftFlowDocument` from a JSON `String`.
public func fromJSONString<NodeData: Codable & Equatable & Sendable, EdgeData: Equatable & Sendable & Hashable & Codable>(
    _ string: String
) throws -> SwiftFlowDocument<NodeData, EdgeData> {
    guard let data = string.data(using: .utf8) else {
        throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Invalid UTF-8 string"))
    }
    return try fromJSON(data)
}
