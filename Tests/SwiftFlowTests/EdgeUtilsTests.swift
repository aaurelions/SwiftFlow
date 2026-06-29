import Testing
import Foundation
@testable import SwiftFlow

@Suite("EdgeUtils")
struct EdgeUtilsTests {

    // MARK: - addEdge

    @Test func addEdgeCreatesNewEdge() {
        let edges: [Edge<EmptyEdgeData>] = []
        let conn = Connection(source: "1", target: "2")
        let result = addEdge(conn, edges: edges)
        #expect(result.count == 1)
        #expect(result[0].source == "1")
        #expect(result[0].target == "2")
    }

    @Test func addEdgePreventsDuplicates() {
        let edges = [Edge<EmptyEdgeData>(id: "e1", source: "1", target: "2")]
        let conn = Connection(source: "1", target: "2")
        let result = addEdge(conn, edges: edges)
        #expect(result.count == 1)
    }

    // MARK: - addEdge handle-aware duplicates

    @Test func addEdgeAllowsDifferentHandlesBetweenSameNodes() {
        // Two edges between the same two nodes but with different handles should be allowed
        let existing = Edge<EmptyEdgeData>(
            id: "e1", source: "1", target: "2",
            sourceHandle: "a", targetHandle: nil
        )
        let edges = [existing]
        let conn = Connection(source: "1", target: "2", sourceHandle: "b", targetHandle: nil)
        let result = addEdge(conn, edges: edges)
        #expect(result.count == 2)
        #expect(result[1].sourceHandle == "b")
    }

    @Test func addEdgePreventsDuplicateWhenHandlesMatch() {
        // Same source, target, sourceHandle, and targetHandle -> duplicate
        let existing = Edge<EmptyEdgeData>(
            id: "e1", source: "1", target: "2",
            sourceHandle: "a", targetHandle: "x"
        )
        let edges = [existing]
        let conn = Connection(source: "1", target: "2", sourceHandle: "a", targetHandle: "x")
        let result = addEdge(conn, edges: edges)
        #expect(result.count == 1)
    }

    @Test func addEdgeTreatsNilHandleAsMatchingNilHandle() {
        // Both edges have nil handles -> duplicate
        let edges = [Edge<EmptyEdgeData>(id: "e1", source: "1", target: "2")]
        let conn = Connection(source: "1", target: "2")
        let result = addEdge(conn, edges: edges)
        #expect(result.count == 1)
    }

    @Test func addEdgeAllowsEdgeWithHandleWhenExistingHasNil() {
        // Existing edge has nil sourceHandle, new connection has a sourceHandle -> allowed
        let existing = Edge<EmptyEdgeData>(id: "e1", source: "1", target: "2")
        let edges = [existing]
        let conn = Connection(source: "1", target: "2", sourceHandle: "a", targetHandle: nil)
        let result = addEdge(conn, edges: edges)
        #expect(result.count == 2)
    }

    @Test func addEdgeAllowsEdgeWithNilHandleWhenExistingHasHandle() {
        // Existing edge has sourceHandle, new connection has nil -> allowed
        let existing = Edge<EmptyEdgeData>(
            id: "e1", source: "1", target: "2", sourceHandle: "a"
        )
        let edges = [existing]
        let conn = Connection(source: "1", target: "2")
        let result = addEdge(conn, edges: edges)
        #expect(result.count == 2)
    }

    @Test func addEdgeTargetHandleAwareDuplicate() {
        // Only targetHandle differs -> allowed
        let existing = Edge<EmptyEdgeData>(
            id: "e1", source: "1", target: "2",
            sourceHandle: "a", targetHandle: "in1"
        )
        let edges = [existing]
        let conn = Connection(source: "1", target: "2", sourceHandle: "a", targetHandle: "in2")
        let result = addEdge(conn, edges: edges)
        #expect(result.count == 2)
        #expect(result[1].targetHandle == "in2")
    }

    @Test func addEdgeWithDefaults() {
        let edges: [Edge<EmptyEdgeData>] = []
        let conn = Connection(source: "1", target: "2")
        let defaults = DefaultEdgeOptions(type: .smoothstep, animated: true, markerEnd: .arrowClosed)
        let result = addEdge(conn, edges: edges, defaults: defaults)
        #expect(result[0].type == .smoothstep)
        #expect(result[0].animated == true)
        #expect(result[0].markerEnd?.type == .arrowClosed)
    }

    @Test func addEdgeWithHandles() {
        let edges: [Edge<EmptyEdgeData>] = []
        let conn = Connection(source: "1", target: "2", sourceHandle: "out", targetHandle: "in")
        let result = addEdge(conn, edges: edges)
        #expect(result[0].sourceHandle == "out")
        #expect(result[0].targetHandle == "in")
    }

    // MARK: - reconnectEdge

    @Test func reconnectEdgeBasic() {
        let edges = [
            Edge<EmptyEdgeData>(id: "e1", source: "1", target: "2", label: "original"),
        ]
        let newConn = Connection(source: "1", target: "3", sourceHandle: "new-out")
        let result = reconnectEdge(edges[0], newConn, edges)
        #expect(result[0].source == "1")
        #expect(result[0].target == "3")
        #expect(result[0].sourceHandle == "new-out")
        #expect(result[0].label == "original")
    }

    @Test func reconnectEdgeNonexistent() {
        let edges = [
            Edge<EmptyEdgeData>(id: "e1", source: "1", target: "2"),
        ]
        let nonexistent = Edge<EmptyEdgeData>(id: "e999", source: "1", target: "2")
        let newConn = Connection(source: "1", target: "3")
        let result = reconnectEdge(nonexistent, newConn, edges)
        #expect(result.count == 1)
        #expect(result[0].target == "2")
    }

    @Test func reconnectEdgePreservesProperties() {
        // reconnectEdge should preserve edge type, animated, markers, label, and style
        // while only changing the connection endpoints
        let existing = Edge<EmptyEdgeData>(
            id: "e1",
            source: "1", target: "2",
            type: .smoothstep,
            label: "my-label",
            animated: true,
            markerEnd: .arrowClosed,
            zIndex: 5,
            reconnectable: true
        )
        let edges = [existing]
        let newConn = Connection(source: "1", target: "3", sourceHandle: "out-a", targetHandle: "in-b")
        let result = reconnectEdge(existing, newConn, edges)
        #expect(result.count == 1)
        #expect(result[0].id == "e1")
        #expect(result[0].source == "1")
        #expect(result[0].target == "3")
        #expect(result[0].sourceHandle == "out-a")
        #expect(result[0].targetHandle == "in-b")
        // Properties that should be preserved:
        #expect(result[0].type == .smoothstep)
        #expect(result[0].animated == true)
        #expect(result[0].label == "my-label")
        #expect(result[0].markerEnd?.type == .arrowClosed)
        #expect(result[0].zIndex == 5)
        #expect(result[0].reconnectable == true)
    }

    @Test func reconnectEdgeMultipleEdgesPreservesUnrelated() {
        // Only the target edge should change; unrelated edges are untouched
        let e1 = Edge<EmptyEdgeData>(id: "e1", source: "1", target: "2", type: .straight)
        let e2 = Edge<EmptyEdgeData>(id: "e2", source: "2", target: "3", type: .bezier)
        let edges = [e1, e2]
        let result = reconnectEdge(e1, Connection(source: "1", target: "4"), edges)
        #expect(result.count == 2)
        #expect(result[0].id == "e1")
        #expect(result[0].target == "4")
        #expect(result[0].type == .straight) // preserved
        #expect(result[1].id == "e2")
        #expect(result[1].source == "2") // untouched
        #expect(result[1].type == .bezier) // untouched
    }

    // MARK: - Edge Paths

    @Test func bezierPathNotEmpty() {
        let path = getBezierPath(sourceX: 0, sourceY: 0, targetX: 200, targetY: 100)
        #expect(!path.isEmpty)
    }

    @Test func straightPathNotEmpty() {
        let path = getStraightPath(sourceX: 0, sourceY: 0, targetX: 200, targetY: 100)
        #expect(!path.isEmpty)
    }

    @Test func stepPathNotEmpty() {
        let path = getStepPath(sourceX: 0, sourceY: 0, targetX: 200, targetY: 100)
        #expect(!path.isEmpty)
    }

    @Test func smoothStepPathNotEmpty() {
        let path = getSmoothStepPath(sourceX: 0, sourceY: 0, targetX: 200, targetY: 100)
        #expect(!path.isEmpty)
    }

    @Test func simpleBezierPathNotEmpty() {
        let path = getSimpleBezierPath(sourceX: 0, sourceY: 0, targetX: 200, targetY: 100)
        #expect(!path.isEmpty)
    }

    @Test func smoothStepPathSameY() {
        let path = getSmoothStepPath(sourceX: 0, sourceY: 50, targetX: 200, targetY: 50)
        #expect(!path.isEmpty)
    }

    @Test func edgePathDispatch() {
        let types: [EdgeType] = [.default, .bezier, .straight, .step, .smoothstep, .simplebezier]
        for type in types {
            let path = getEdgePath(type: type, sourceX: 0, sourceY: 0, targetX: 200, targetY: 100)
            #expect(!path.isEmpty, "Path should not be empty for type \(type)")
        }
    }

    @Test func edgePathResultValues() {
        let result = getEdgePathResult(type: .bezier, sourceX: 0, sourceY: 0, targetX: 200, targetY: 100)
        #expect(!result.path.isEmpty)
        #expect(result.sourceX == 0)
        #expect(result.sourceY == 0)
        #expect(result.targetX == 200)
        #expect(result.targetY == 100)
    }

    @Test func edgeMidpointStraight() {
        let mid = getEdgeMidpoint(type: .straight, sourceX: 0, sourceY: 0, targetX: 200, targetY: 100)
        #expect(mid.x == 100)
        #expect(mid.y == 50)
    }

    @Test func edgeAngleAtEndHorizontal() {
        let angle = getEdgeAngleAtEnd(type: .straight, sourceX: 0, sourceY: 0, targetX: 100, targetY: 0)
        #expect(abs(angle) < 0.01)
    }

    @Test func edgeAngleAtStartVertical() {
        let angle = getEdgeAngleAtStart(type: .straight, sourceX: 0, sourceY: 0, targetX: 0, targetY: 100)
        #expect(abs(angle - .pi / 2) < 0.01)
    }

    // MARK: - Position-Aware Paths

    @Test func bezierPathWithPositions() {
        let result = getBezierPath(
            sourceX: 0, sourceY: 0, sourcePosition: .right,
            targetX: 200, targetY: 100, targetPosition: .left
        )
        #expect(!result.path.isEmpty)
        #expect(result.labelX > 0 && result.labelX < 200)
    }

    @Test func stepPathWithPositions() {
        let result = getStepPath(
            sourceX: 0, sourceY: 0, sourcePosition: .right,
            targetX: 200, targetY: 100, targetPosition: .left
        )
        #expect(!result.path.isEmpty)
        #expect(result.labelX == 100)
        #expect(result.labelY == 50)
    }

    @Test func smoothStepPathWithPositions() {
        let result = getSmoothStepPath(
            sourceX: 0, sourceY: 0, sourcePosition: .right,
            targetX: 200, targetY: 100, targetPosition: .left
        )
        #expect(!result.path.isEmpty)
    }

    @Test func simpleBezierPathWithPositions() {
        let result = getSimpleBezierPath(
            sourceX: 0, sourceY: 0, sourcePosition: .right,
            targetX: 200, targetY: 100, targetPosition: .left
        )
        #expect(!result.path.isEmpty)
    }

    @Test func edgePathWithPositionsAllTypes() {
        let types: [EdgeType] = [.default, .bezier, .straight, .step, .smoothstep, .simplebezier]
        for type in types {
            let result = getEdgePath(
                type: type,
                sourceX: 0, sourceY: 0, sourcePosition: .right,
                targetX: 200, targetY: 100, targetPosition: .left
            )
            #expect(!result.path.isEmpty, "Position-aware path empty for \(type)")
        }
    }

    @Test func smoothStepVerticalPath() {
        let result = getSmoothStepPath(
            sourceX: 0, sourceY: 0, sourcePosition: .bottom,
            targetX: 100, targetY: 200, targetPosition: .top
        )
        #expect(!result.path.isEmpty)
    }

    @Test func smoothStepVerticalSameX() {
        let result = getSmoothStepPath(
            sourceX: 100, sourceY: 0, sourcePosition: .bottom,
            targetX: 100, targetY: 200, targetPosition: .top
        )
        #expect(!result.path.isEmpty)
    }
}
