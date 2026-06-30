import Foundation
import Testing

@testable import SwiftFlow

@Suite("Edge")
struct EdgeTests {

  @Test func initWithDefaults() {
    let edge = Edge<EmptyEdgeData>(id: "e1", source: "1", target: "2")
    #expect(edge.id == "e1")
    #expect(edge.source == "1")
    #expect(edge.target == "2")
    #expect(edge.sourceHandle == nil)
    #expect(edge.targetHandle == nil)
    #expect(edge.type == .default)
    #expect(edge.selected == false)
    #expect(edge.hidden == false)
    #expect(edge.label == nil)
    #expect(edge.animated == false)
    #expect(edge.markerStart == nil)
    #expect(edge.markerEnd == nil)
    #expect(edge.zIndex == 0)
    #expect(edge.reconnectable == false)
    #expect(edge.deletable == true)
    #expect(edge.focusable == true)
    #expect(edge.interactionWidth == 20)
    #expect(edge.data == nil)
    #expect(edge.style == nil)
  }

  @Test func initWithCustomValues() {
    let edge = Edge<EmptyEdgeData>(
      id: "e1", source: "1", target: "2",
      sourceHandle: "out", targetHandle: "in",
      type: .smoothstep, selected: true, hidden: true,
      label: "Flow", animated: true,
      markerStart: .arrow, markerEnd: .arrowClosed,
      zIndex: 5, reconnectable: true, deletable: false,
      focusable: false, interactionWidth: 30,
      data: EmptyEdgeData()
    )
    #expect(edge.sourceHandle == "out")
    #expect(edge.targetHandle == "in")
    #expect(edge.type == .smoothstep)
    #expect(edge.selected == true)
    #expect(edge.label == "Flow")
    #expect(edge.animated == true)
    #expect(edge.reconnectable == true)
    #expect(edge.deletable == false)
    #expect(edge.interactionWidth == 30)
  }

  @Test func codableRoundTrip() throws {
    let edge = Edge<EmptyEdgeData>(
      id: "e1", source: "1", target: "2",
      type: .smoothstep, label: "test", reconnectable: true
    )
    let data = try JSONEncoder().encode(edge)
    let decoded = try JSONDecoder().decode(Edge<EmptyEdgeData>.self, from: data)
    #expect(decoded.id == "e1")
    #expect(decoded.source == "1")
    #expect(decoded.target == "2")
    #expect(decoded.type == .smoothstep)
    #expect(decoded.label == "test")
    #expect(decoded.reconnectable == true)
  }

  @Test func codableDefaults() throws {
    let json = """
      {"id": "e1", "source": "1", "target": "2"}
      """
    let edge = try JSONDecoder().decode(Edge<EmptyEdgeData>.self, from: json.data(using: .utf8)!)
    #expect(edge.type == .default)
    #expect(edge.selected == false)
    #expect(edge.reconnectable == false)
    #expect(edge.deletable == true)
    #expect(edge.interactionWidth == 20)
  }

  @Test func equatable() {
    let a = Edge<EmptyEdgeData>(id: "e1", source: "1", target: "2")
    let b = Edge<EmptyEdgeData>(id: "e1", source: "1", target: "2")
    let c = Edge<EmptyEdgeData>(id: "e2", source: "1", target: "2")
    #expect(a == b)
    #expect(a != c)
  }

  @Test func hashable() {
    let a = Edge<EmptyEdgeData>(id: "e1", source: "1", target: "2")
    let b = Edge<EmptyEdgeData>(id: "e1", source: "1", target: "2")
    var set: Set<Edge<EmptyEdgeData>> = []
    set.insert(a)
    set.insert(b)
    #expect(set.count == 1)
  }

  @Test func edgeTypeRawValues() {
    #expect(EdgeType.default.rawValue == "default")
    #expect(EdgeType.bezier.rawValue == "bezier")
    #expect(EdgeType.straight.rawValue == "straight")
    #expect(EdgeType.step.rawValue == "step")
    #expect(EdgeType.smoothstep.rawValue == "smoothstep")
    #expect(EdgeType.simplebezier.rawValue == "simplebezier")
  }

  @Test func markerTypes() {
    #expect(MarkerType.arrow.rawValue == "arrow")
    #expect(MarkerType.arrowClosed.rawValue == "arrowclosed")
  }

  @Test func edgeMarkerDefaults() {
    let arrow = EdgeMarker.arrow
    #expect(arrow.type == .arrow)
    #expect(arrow.width == 12)
    #expect(arrow.height == 12)

    let closed = EdgeMarker.arrowClosed
    #expect(closed.type == .arrowClosed)
  }

  @Test func edgeWithCustomData() {
    struct FlowData: Equatable, Sendable, Hashable, Codable {
      var weight: Double
    }
    let edge = Edge(id: "e1", source: "1", target: "2", data: FlowData(weight: 1.5))
    #expect(edge.data?.weight == 1.5)
  }
}
