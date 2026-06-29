import Testing
import Foundation
@testable import SwiftFlow

@Suite("ChangeUtils")
struct ChangeUtilsTests {

    // MARK: - Node Changes

    @Test func applyNodePositionChange() {
        let nodes = [Node(id: "1", position: .zero, data: "A")]
        let result = applyNodeChanges([.position(id: "1", position: XYPosition(x: 100, y: 200))], nodes: nodes)
        #expect(result[0].position == XYPosition(x: 100, y: 200))
    }

    @Test func applyNodeSelectionChange() {
        let nodes = [Node(id: "1", position: .zero, data: "A")]
        let result = applyNodeChanges([.selection(id: "1", selected: true)], nodes: nodes)
        #expect(result[0].selected == true)
    }

    @Test func applyNodeRemove() {
        let nodes = [
            Node(id: "1", position: .zero, data: "A"),
            Node(id: "2", position: .zero, data: "B"),
        ]
        let result = applyNodeChanges([.remove(id: "1")], nodes: nodes)
        #expect(result.count == 1)
        #expect(result[0].id == "2")
    }

    @Test func applyNodeAdd() {
        let nodes = [Node(id: "1", position: .zero, data: "A")]
        let newNode = Node(id: "2", position: XYPosition(x: 100, y: 100), data: "B")
        let result = applyNodeChanges([.add(item: newNode)], nodes: nodes)
        #expect(result.count == 2)
        #expect(result[1].id == "2")
    }

    @Test func applyNodeAddPreventsDuplicate() {
        let nodes = [Node(id: "1", position: .zero, data: "A")]
        let duplicate = Node(id: "1", position: XYPosition(x: 999, y: 999), data: "X")
        let result = applyNodeChanges([.add(item: duplicate)], nodes: nodes)
        #expect(result.count == 1)
        #expect(result[0].data == "A") // Original unchanged
    }

    @Test func applyNodeDimensions() {
        let nodes = [Node(id: "1", position: .zero, data: "A")]
        let result = applyNodeChanges([.dimensions(id: "1", width: 300, height: 150)], nodes: nodes)
        #expect(result[0].width == 300)
        #expect(result[0].height == 150)
    }

    @Test func applyNodeReplace() {
        let nodes = [Node(id: "1", position: .zero, data: "A")]
        let replacement = Node(id: "1", position: XYPosition(x: 50, y: 50), data: "B")
        let result = applyNodeChanges([.replace(id: "1", item: replacement)], nodes: nodes)
        #expect(result[0].data == "B")
        #expect(result[0].position == XYPosition(x: 50, y: 50))
    }

    @Test func applyMultipleNodeChanges() {
        let nodes = [
            Node(id: "1", position: .zero, data: "A"),
            Node(id: "2", position: .zero, data: "B"),
        ]
        let changes: [NodeChange<String>] = [
            .selection(id: "1", selected: true),
            .position(id: "2", position: XYPosition(x: 50, y: 50)),
        ]
        let result = applyNodeChanges(changes, nodes: nodes)
        #expect(result[0].selected == true)
        #expect(result[1].position == XYPosition(x: 50, y: 50))
    }

    @Test func applyNodeChangeNonexistentId() {
        let nodes = [Node(id: "1", position: .zero, data: "A")]
        let result = applyNodeChanges([.position(id: "nonexistent", position: XYPosition(x: 100, y: 100))], nodes: nodes)
        #expect(result.count == 1)
        #expect(result[0].position == .zero) // Unchanged
    }

    // MARK: - Edge Changes

    @Test func applyEdgeSelectionChange() {
        let edges = [Edge<EmptyEdgeData>(id: "e1", source: "1", target: "2")]
        let result = applyEdgeChanges([.selection(id: "e1", selected: true)], edges: edges)
        #expect(result[0].selected == true)
    }

    @Test func applyEdgeRemove() {
        let edges = [
            Edge<EmptyEdgeData>(id: "e1", source: "1", target: "2"),
            Edge<EmptyEdgeData>(id: "e2", source: "2", target: "3"),
        ]
        let result = applyEdgeChanges([.remove(id: "e1")], edges: edges)
        #expect(result.count == 1)
        #expect(result[0].id == "e2")
    }

    @Test func applyEdgeAdd() {
        let edges: [Edge<EmptyEdgeData>] = []
        let newEdge = Edge<EmptyEdgeData>(id: "e1", source: "1", target: "2")
        let result = applyEdgeChanges([.add(item: newEdge)], edges: edges)
        #expect(result.count == 1)
    }

    @Test func applyEdgeAddPreventsDuplicate() {
        let edges = [Edge<EmptyEdgeData>(id: "e1", source: "1", target: "2")]
        let duplicate = Edge<EmptyEdgeData>(id: "e1", source: "3", target: "4")
        let result = applyEdgeChanges([.add(item: duplicate)], edges: edges)
        #expect(result.count == 1)
        #expect(result[0].source == "1") // Original unchanged
    }

    @Test func applyEdgeReplace() {
        let edges = [Edge<EmptyEdgeData>(id: "e1", source: "1", target: "2")]
        let replacement = Edge<EmptyEdgeData>(id: "e1", source: "1", target: "3", label: "updated")
        let result = applyEdgeChanges([.replace(id: "e1", item: replacement)], edges: edges)
        #expect(result[0].target == "3")
        #expect(result[0].label == "updated")
    }
}
