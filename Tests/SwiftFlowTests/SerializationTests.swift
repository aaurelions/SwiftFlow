import Foundation
import SwiftUI
import Testing

@testable import SwiftFlow

@Suite("Serialization")
struct SerializationTests {

  @Test func jsonRoundTrip() throws {
    let nodes = [
      Node(id: "1", position: XYPosition(x: 10, y: 20), data: "Hello"),
      Node(id: "2", position: XYPosition(x: 200, y: 100), data: "World"),
    ]
    let edges = [
      FlowEdge<EmptyEdgeData>(id: "e1", source: "1", target: "2")
    ]
    let vp = Viewport(x: 50, y: 60, zoom: 1.5)

    let data = try toJSON(nodes: nodes, edges: edges, viewport: vp)
    let doc: SwiftFlowDocument<String, EmptyEdgeData> = try fromJSON(data)

    #expect(doc.nodes.count == 2)
    #expect(doc.edges.count == 1)
    #expect(doc.viewport?.zoom == 1.5)
    #expect(doc.nodes[0].data == "Hello")
  }

  @Test func jsonStringRoundTrip() throws {
    let nodes = [Node(id: "1", position: .zero, data: "Test")]
    let edges: [FlowEdge<EmptyEdgeData>] = []

    let jsonString = try toJSONString(nodes: nodes, edges: edges)
    #expect(jsonString.contains("\"Test\""))

    let doc: SwiftFlowDocument<String, EmptyEdgeData> = try fromJSONString(jsonString)
    #expect(doc.nodes.count == 1)
    #expect(doc.nodes[0].data == "Test")
  }

  @Test func jsonWithoutViewport() throws {
    let nodes = [Node(id: "1", position: .zero, data: "A")]
    let edges: [FlowEdge<EmptyEdgeData>] = []

    let data = try toJSON(nodes: nodes, edges: edges)
    let doc: SwiftFlowDocument<String, EmptyEdgeData> = try fromJSON(data)
    #expect(doc.viewport == nil)
  }

  @Test func invalidUTF8Throws() throws {
    #expect(throws: DecodingError.self) {
      let _: SwiftFlowDocument<String, EmptyEdgeData> = try fromJSONString("\u{00}")
    }
  }

  @Test func documentInit() {
    let doc = SwiftFlowDocument<String, EmptyEdgeData>(
      nodes: [Node(id: "1", position: .zero, data: "A")],
      edges: []
    )
    #expect(doc.nodes.count == 1)
    #expect(doc.edges.isEmpty)
    #expect(doc.viewport == nil)
  }

  @Test func documentWithViewport() {
    let doc = SwiftFlowDocument<String, EmptyEdgeData>(
      nodes: [], edges: [], viewport: .identity
    )
    #expect(doc.viewport == .identity)
  }

  @Test func customEdgeDataRoundTrip() throws {
    struct Weight: Equatable, Sendable, Hashable, Codable { var value: Double }
    let edges = [
      FlowEdge(id: "e1", source: "1", target: "2", data: Weight(value: 3.14))
    ]
    let nodes = [Node(id: "1", position: .zero, data: "A")]
    let data = try toJSON(nodes: nodes, edges: edges)
    let doc: SwiftFlowDocument<String, Weight> = try fromJSON(data)
    #expect(doc.edges[0].data?.value == 3.14)
  }

  @Test func edgeCodablePreservesAllFields() throws {
    let edge = FlowEdge<EmptyEdgeData>(
      id: "e1", source: "1", target: "2",
      sourceHandle: "out", targetHandle: "in",
      type: .smoothstep, selected: true, hidden: true,
      label: "Flow", animated: true,
      zIndex: 5, reconnectable: true, deletable: false,
      focusable: false, interactionWidth: 30
    )
    let data = try JSONEncoder().encode(edge)
    let decoded = try JSONDecoder().decode(FlowEdge<EmptyEdgeData>.self, from: data)
    #expect(decoded.sourceHandle == "out")
    #expect(decoded.targetHandle == "in")
    #expect(decoded.type == .smoothstep)
    #expect(decoded.selected == true)
    #expect(decoded.hidden == true)
    #expect(decoded.label == "Flow")
    #expect(decoded.animated == true)
    #expect(decoded.zIndex == 5)
    #expect(decoded.reconnectable == true)
    #expect(decoded.deletable == false)
    #expect(decoded.focusable == false)
    #expect(decoded.interactionWidth == 30)
  }

  @Test func nodeCodablePreservesExtentAndStyle() throws {
    let node = Node(
      id: "styled", position: XYPosition(x: 10, y: 20), data: "A",
      extent: .coordinateExtent(CoordinateExtent(minX: -10, minY: -20, maxX: 300, maxY: 400)),
      style: NodeStyle(
        backgroundColor: Color(red: 0.1, green: 0.2, blue: 0.3, opacity: 0.4),
        borderColor: Color(red: 0.8, green: 0.7, blue: 0.6, opacity: 0.5),
        borderWidth: 2,
        borderRadius: 8,
        opacity: 0.75
      )
    )

    let data = try JSONEncoder().encode(node)
    let decoded = try JSONDecoder().decode(Node<String>.self, from: data)

    #expect(decoded.extent == node.extent)
    #expect(decoded.style?.borderWidth == 2)
    #expect(decoded.style?.borderRadius == 8)
    #expect(decoded.style?.opacity == 0.75)
    #expect(decoded.style?.backgroundColor != nil)
    #expect(decoded.style?.borderColor != nil)
  }

  @Test func edgeCodablePreservesStyle() throws {
    let edge = FlowEdge<EmptyEdgeData>(
      id: "styled-edge", source: "1", target: "2",
      style: EdgeStyle(
        strokeColor: Color(red: 0.2, green: 0.4, blue: 0.6, opacity: 0.8),
        strokeWidth: 3,
        opacity: 0.5
      )
    )

    let data = try JSONEncoder().encode(edge)
    let decoded = try JSONDecoder().decode(FlowEdge<EmptyEdgeData>.self, from: data)

    #expect(decoded.style?.strokeColor != nil)
    #expect(decoded.style?.strokeWidth == 3)
    #expect(decoded.style?.opacity == 0.5)
  }
}
