import Foundation
import Testing

@testable import SwiftFlow

@Suite("SwiftFlowState")
struct SwiftFlowStateTests {

  // MARK: - AnyNodeSnapshot

  @Test func anyNodeSnapshotFromNode() {
    let node = Node(
      id: "1", position: XYPosition(x: 10, y: 20), data: "Hello",
      type: "custom", selected: true, hidden: true)
    let snapshot = AnyNodeSnapshot(from: node)
    #expect(snapshot.id == "1")
    #expect(snapshot.x == 10)
    #expect(snapshot.y == 20)
    #expect(snapshot.selected == true)
    #expect(snapshot.hidden == true)
    #expect(snapshot.type == "custom")
  }

  @Test func anyNodeSnapshotEquatable() {
    let node = Node(id: "1", position: .zero, data: "A")
    let a = AnyNodeSnapshot(from: node)
    let b = AnyNodeSnapshot(from: node)
    #expect(a == b)
  }

  // MARK: - AnyEdgeSnapshot

  @Test func anyEdgeSnapshotFromEdge() {
    let edge = Edge<EmptyEdgeData>(
      id: "e1", source: "1", target: "2",
      sourceHandle: "out", targetHandle: "in",
      type: .smoothstep, selected: true, hidden: true,
      label: "Flow", animated: true,
      markerStart: .arrow, markerEnd: .arrowClosed,
      zIndex: 5, reconnectable: true, deletable: false
    )
    let snapshot = AnyEdgeSnapshot(from: edge)
    #expect(snapshot.id == "e1")
    #expect(snapshot.source == "1")
    #expect(snapshot.target == "2")
    #expect(snapshot.sourceHandle == "out")
    #expect(snapshot.targetHandle == "in")
    #expect(snapshot.type == .smoothstep)
    #expect(snapshot.selected == true)
    #expect(snapshot.hidden == true)
    #expect(snapshot.label == "Flow")
    #expect(snapshot.animated == true)
    #expect(snapshot.markerStart?.type == .arrow)
    #expect(snapshot.markerEnd?.type == .arrowClosed)
    #expect(snapshot.zIndex == 5)
    #expect(snapshot.reconnectable == true)
    #expect(snapshot.deletable == false)
  }

  // MARK: - SwiftFlowState

  @MainActor
  @Test func defaultState() {
    let state = SwiftFlowState()
    #expect(state.viewport == .identity)
    #expect(state.viewSize == .zero)
    #expect(state.nodeSizes.isEmpty)
    #expect(state.absolutePositions.isEmpty)
    #expect(state.handlePositions.isEmpty)
    #expect(state.handleTypes.isEmpty)
    #expect(state.nodes.isEmpty)
    #expect(state.edges.isEmpty)
    #expect(state.activeConnection == nil)
    #expect(state.connectionsMap.isEmpty)
  }

  @MainActor
  @Test func connectionsMap() {
    let state = SwiftFlowState()
    state.connectionsMap = [
      "1": [Connection(source: "1", target: "2")],
      "2": [Connection(source: "1", target: "2")],
    ]
    #expect(state.connectionsMap["1"]?.count == 1)
    #expect(state.connectionsMap["2"]?.count == 1)
    #expect(state.connectionsMap["3"] == nil)
  }

  @MainActor
  @Test func activeConnectionState() {
    let state = SwiftFlowState()
    let fromNode = AnyNodeSnapshot(from: Node(id: "1", position: .zero, data: "A"))
    let connState = ConnectionState(
      isValid: true,
      from: CGPoint(x: 100, y: 50),
      fromHandle: NodeHandle(id: "out", type: .source, position: .right),
      fromPosition: .right,
      fromNode: fromNode,
      to: CGPoint(x: 300, y: 150)
    )
    state.activeConnection = connState
    #expect(state.activeConnection?.isValid == true)
    #expect(state.activeConnection?.from == CGPoint(x: 100, y: 50))
    #expect(state.activeConnection?.fromHandle.id == "out")
    #expect(state.activeConnection?.toHandle == nil)

    state.activeConnection = nil
    #expect(state.activeConnection == nil)
  }

  @MainActor
  @Test func zoomIn() {
    let state = SwiftFlowState()
    state.viewport = Viewport(x: 0, y: 0, zoom: 1.0)
    state.viewSize = CGSize(width: 800, height: 600)
    var appliedViewport: Viewport?
    state.applyViewport = { vp, _ in appliedViewport = vp }
    state.zoomIn()
    #expect(appliedViewport?.zoom == 1.25)
  }

  @MainActor
  @Test func zoomOut() {
    let state = SwiftFlowState()
    state.viewport = Viewport(x: 0, y: 0, zoom: 1.0)
    state.viewSize = CGSize(width: 800, height: 600)
    var appliedViewport: Viewport?
    state.applyViewport = { vp, _ in appliedViewport = vp }
    state.zoomOut()
    #expect(appliedViewport != nil)
    #expect(appliedViewport!.zoom < 1.0)
  }

  @MainActor
  @Test func zoomTo() {
    let state = SwiftFlowState()
    state.viewport = Viewport(x: 0, y: 0, zoom: 1.0)
    state.viewSize = CGSize(width: 800, height: 600)
    var appliedViewport: Viewport?
    state.applyViewport = { vp, _ in appliedViewport = vp }
    state.zoomTo(2.0)
    #expect(appliedViewport?.zoom == 2.0)
  }

  @MainActor
  @Test func zoomToClamp() {
    let state = SwiftFlowState()
    state.viewport = Viewport(x: 0, y: 0, zoom: 1.0)
    state.viewSize = CGSize(width: 800, height: 600)
    var appliedViewport: Viewport?
    state.applyViewport = { vp, _ in appliedViewport = vp }
    state.zoomTo(100.0)  // Way above max
    #expect(appliedViewport?.zoom == Viewport.maxZoom)
  }

  @MainActor
  @Test func setViewport() {
    let state = SwiftFlowState()
    var appliedViewport: Viewport?
    var appliedAnimated: Bool?
    state.applyViewport = { vp, animated in
      appliedViewport = vp
      appliedAnimated = animated
    }
    let vp = Viewport(x: 50, y: 100, zoom: 2.0)
    state.setViewport(vp, animated: false)
    #expect(appliedViewport == vp)
    #expect(appliedAnimated == false)
  }

  @MainActor
  @Test func setViewportAnimated() {
    let state = SwiftFlowState()
    var appliedAnimated: Bool?
    state.applyViewport = { _, animated in appliedAnimated = animated }
    state.setViewport(.identity, animated: true)
    #expect(appliedAnimated == true)
  }

  @MainActor
  @Test func fitView() {
    let state = SwiftFlowState()
    state.viewSize = CGSize(width: 800, height: 600)
    state.nodes = [
      AnyNodeSnapshot(from: Node(id: "1", position: XYPosition(x: 0, y: 0), data: "A")),
      AnyNodeSnapshot(from: Node(id: "2", position: XYPosition(x: 200, y: 100), data: "B")),
    ]
    state.nodeSizes = [
      "1": CGSize(width: 100, height: 50),
      "2": CGSize(width: 100, height: 50),
    ]
    var appliedViewport: Viewport?
    state.applyViewport = { vp, _ in appliedViewport = vp }
    state.fitView()
    #expect(appliedViewport != nil)
    #expect(appliedViewport!.zoom > 0)
    #expect(appliedViewport!.zoom <= 1.5)  // default maxZoom
  }

  @MainActor
  @Test func fitViewHiddenExcluded() {
    let state = SwiftFlowState()
    state.viewSize = CGSize(width: 800, height: 600)
    state.nodes = [
      AnyNodeSnapshot(from: Node(id: "1", position: XYPosition(x: 0, y: 0), data: "A")),
      AnyNodeSnapshot(
        from: Node(id: "2", position: XYPosition(x: 1000, y: 1000), data: "B", hidden: true)),
    ]
    state.nodeSizes = ["1": CGSize(width: 100, height: 50)]
    var appliedViewport: Viewport?
    state.applyViewport = { vp, _ in appliedViewport = vp }
    state.fitView()
    #expect(appliedViewport != nil)
  }

  @MainActor
  @Test func fitViewEmptyNoOp() {
    let state = SwiftFlowState()
    state.viewSize = CGSize(width: 800, height: 600)
    state.nodes = []
    var called = false
    state.applyViewport = { _, _ in called = true }
    state.fitView()
    #expect(!called)  // No nodes, should not call applyViewport
  }

  @MainActor
  @Test func fitViewWithAbsolutePositions() {
    let state = SwiftFlowState()
    state.viewSize = CGSize(width: 800, height: 600)
    state.nodes = [
      AnyNodeSnapshot(from: Node(id: "1", position: XYPosition(x: 0, y: 0), data: "A"))
    ]
    state.absolutePositions = ["1": XYPosition(x: 50, y: 50)]
    state.nodeSizes = ["1": CGSize(width: 100, height: 50)]
    var appliedViewport: Viewport?
    state.applyViewport = { vp, _ in appliedViewport = vp }
    state.fitView()
    #expect(appliedViewport != nil)
  }
}
