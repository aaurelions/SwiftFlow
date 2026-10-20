import Foundation
import SwiftUI
import Testing

@testable import SwiftFlow

/// Checks the edge path helpers against values computed with React Flow's formulas.
@Suite("EdgePathParity")
struct EdgePathParityTests {

  // MARK: - Bezier

  @Test func bezierLabelMatchesReactFlow() {
    // Controls: (0 + 0.5 * 200, 0) and (200 - 0.5 * 200, 100).
    let result = getBezierPath(
      sourceX: 0, sourceY: 0, sourcePosition: .right,
      targetX: 200, targetY: 100, targetPosition: .left)
    #expect(result.labelX == 100)
    #expect(result.labelY == 50)
    #expect(result.offsetX == 100)
    #expect(result.offsetY == 50)
  }

  @Test func bezierLoopsWhenTargetIsBehindSource() {
    // Source control: 0.25 * 25 * sqrt(100) = 62.5; target control: -100 - 62.5.
    let result = getBezierPath(
      sourceX: 0, sourceY: 0, sourcePosition: .right,
      targetX: -100, targetY: 0, targetPosition: .left)
    #expect(abs(result.labelX - -50) < 0.0001)
    #expect(result.labelY == 0)
  }

  @Test func verticalBezierUsesHandleSides() {
    let result = getBezierPath(
      sourceX: 0, sourceY: 0, sourcePosition: .bottom,
      targetX: 0, targetY: 200, targetPosition: .top)
    #expect(result.labelX == 0)
    #expect(result.labelY == 100)
    let bounds = result.path.boundingRect
    #expect(bounds.width < 0.001)  // Straight down, no horizontal bulge.
  }

  // MARK: - Simple Bezier / Straight

  @Test func simpleBezierIsCubicThroughMidpoint() {
    let result = getSimpleBezierPath(
      sourceX: 0, sourceY: 0, sourcePosition: .right,
      targetX: 200, targetY: 100, targetPosition: .left)
    #expect(result.labelX == 100)
    #expect(result.labelY == 50)
  }

  @Test func straightPathCenterAndOffsets() {
    let result = getEdgePath(
      type: .straight,
      sourceX: 0, sourceY: 0, sourcePosition: .right,
      targetX: 200, targetY: 100, targetPosition: .left)
    #expect(result.labelX == 100)
    #expect(result.labelY == 50)
    #expect(result.offsetX == 100)
    #expect(result.offsetY == 50)
  }

  // MARK: - Smooth Step

  @Test func smoothStepRightToTopEntersFromAbove() {
    // React Flow routes (0,0) -> (20,0) -> (100,0) -> (100,80) -> (100,100).
    let result = getSmoothStepPath(
      sourceX: 0, sourceY: 0, sourcePosition: .right,
      targetX: 100, targetY: 100, targetPosition: .top)
    #expect(result.labelX == 60)
    #expect(result.labelY == 0)
    let bounds = result.path.boundingRect
    #expect(bounds.minX >= 0 && bounds.maxX <= 100)
    #expect(bounds.minY >= 0 && bounds.maxY <= 100)
  }

  @Test func smoothStepOppositeSidesSplitAtCenter() {
    let result = getSmoothStepPath(
      sourceX: 0, sourceY: 0, sourcePosition: .right,
      targetX: 200, targetY: 100, targetPosition: .left)
    #expect(result.labelX == 100)
    #expect(result.labelY == 50)
  }

  @Test func smoothStepHonorsCenterX() {
    let result = getSmoothStepPath(
      sourceX: 0, sourceY: 0, sourcePosition: .right,
      targetX: 200, targetY: 100, targetPosition: .left,
      centerX: 40)
    #expect(result.labelX == 40)
  }

  @Test func smoothStepSameSideLoopsAroundOffset() {
    // Both handles face right; the path must leave and re-enter to the right.
    let result = getSmoothStepPath(
      sourceX: 0, sourceY: 0, sourcePosition: .right,
      targetX: 0, targetY: 100, targetPosition: .right)
    #expect(result.path.boundingRect.maxX >= 19)
  }

  @Test func stepIsSmoothStepWithoutRadius() {
    let step = getStepPath(
      sourceX: 0, sourceY: 0, sourcePosition: .bottom,
      targetX: 100, targetY: 200, targetPosition: .top)
    let smooth = getSmoothStepPath(
      sourceX: 0, sourceY: 0, sourcePosition: .bottom,
      targetX: 100, targetY: 200, targetPosition: .top, borderRadius: 0)
    #expect(step.path.boundingRect == smooth.path.boundingRect)
    #expect(step.labelX == smooth.labelX && step.labelY == smooth.labelY)
  }

  // MARK: - Markers

  @Test func endMarkerPointsIntoTopHandle() {
    let angle = edgeEndAngle(
      type: .default,
      source: CGPoint(x: 0, y: 0), sourcePosition: .bottom,
      target: CGPoint(x: 100, y: 200), targetPosition: .top)
    #expect(abs(angle - .pi / 2) < 0.0001)
  }

  @Test func startMarkerFollowsSourceSide() {
    let angle = edgeStartAngle(
      type: .smoothstep,
      source: .zero, sourcePosition: .left,
      target: CGPoint(x: 100, y: 0), targetPosition: .right)
    #expect(abs(abs(angle) - .pi) < 0.0001)
  }

  // MARK: - addEdge

  @Test func addEdgeUsesReactFlowIdFormat() {
    let edges = addEdge(
      Connection(source: "1", target: "2", sourceHandle: "a", targetHandle: "b"),
      edges: [] as [FlowEdge<EmptyEdgeData>])
    #expect(edges.map(\.id) == ["xy-edge__1a-2b"])
  }

  @Test func addEdgeTreatsEmptyAndNilHandlesAsEqual() {
    let existing = [FlowEdge<EmptyEdgeData>(id: "e", source: "1", target: "2", sourceHandle: "")]
    let edges = addEdge(Connection(source: "1", target: "2"), edges: existing)
    #expect(edges.count == 1)
  }

  @Test func defaultEdgeOptionsFillOnlyUnsetValues() {
    let defaults = DefaultEdgeOptions(type: .step, animated: true, markerEnd: .arrow)
    let explicit = FlowEdge<EmptyEdgeData>(
      id: "e", source: "1", target: "2", type: .straight, markerEnd: .arrowClosed)
    let applied = defaults.applied(to: explicit)
    #expect(applied.type == .straight)
    #expect(applied.animated)
    #expect(applied.markerEnd == .arrowClosed)

    let plain = defaults.applied(to: FlowEdge<EmptyEdgeData>(id: "p", source: "1", target: "2"))
    #expect(plain.type == .step)
    #expect(plain.markerEnd == .arrow)
  }

  // MARK: - Handle Lookup

  @Test func edgeWithoutHandleIdUsesFirstHandleOfType() {
    let sourceKey = HandlePositionPreferenceKey.makeKey(nodeId: "1", handleId: "b", type: .source)
    let otherKey = HandlePositionPreferenceKey.makeKey(nodeId: "1", handleId: "a", type: .target)
    let lookup = HandleLookup(
      positions: [sourceKey: CGPoint(x: 10, y: 0), otherKey: .zero],
      types: [sourceKey: .source, otherKey: .target],
      infos: [:])
    #expect(lookup.key(nodeId: "1", handleId: nil, type: .source) == sourceKey)
    #expect(lookup.key(nodeId: "1", handleId: "missing", type: .source) == nil)
  }
}
