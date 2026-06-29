import Testing
import Foundation
@testable import SwiftFlow

@Suite("Node")
struct NodeTests {

    @Test func initWithDefaults() {
        let node = Node(id: "1", position: .zero, data: "Hello")
        #expect(node.id == "1")
        #expect(node.position == .zero)
        #expect(node.data == "Hello")
        #expect(node.type == "default")
        #expect(node.parentId == nil)
        #expect(node.selected == false)
        #expect(node.hidden == false)
        #expect(node.width == nil)
        #expect(node.height == nil)
        #expect(node.draggable == true)
        #expect(node.selectable == true)
        #expect(node.connectable == true)
        #expect(node.deletable == true)
        #expect(node.expandable == false)
        #expect(node.expanded == true)
        #expect(node.expandParent == false)
        #expect(node.focusable == true)
        #expect(node.zIndex == 0)
        #expect(node.origin == .topLeft)
        #expect(node.sourcePosition == nil)
        #expect(node.targetPosition == nil)
        #expect(node.extent == nil)
        #expect(node.style == nil)
    }

    @Test func initWithCustomValues() {
        let node = Node(
            id: "n1", position: XYPosition(x: 100, y: 200), data: 42,
            type: "custom", parentId: "parent", selected: true, hidden: true,
            width: 300, height: 150, draggable: false, selectable: false,
            connectable: false, deletable: false, expandable: true, expanded: false,
            expandParent: true, focusable: false, zIndex: 5,
            origin: .center, sourcePosition: .right, targetPosition: .left,
            extent: .parent
        )
        #expect(node.type == "custom")
        #expect(node.parentId == "parent")
        #expect(node.selected == true)
        #expect(node.hidden == true)
        #expect(node.width == 300)
        #expect(node.height == 150)
        #expect(node.draggable == false)
        #expect(node.expandable == true)
        #expect(node.expanded == false)
        #expect(node.extent == .parent)
        #expect(node.sourcePosition == .right)
        #expect(node.targetPosition == .left)
    }

    @Test func extentParent() {
        let node = Node(id: "1", position: .zero, data: "x", extent: .parent)
        #expect(node.extent == .parent)
    }

    @Test func extentCoordinate() {
        let ce = CoordinateExtent(minX: 0, minY: 0, maxX: 500, maxY: 500)
        let node = Node(id: "1", position: .zero, data: "x", extent: .coordinateExtent(ce))
        if case .coordinateExtent(let ext) = node.extent {
            #expect(ext.maxX == 500)
        } else {
            Issue.record("Expected .coordinateExtent")
        }
    }

    @Test func equatable() {
        let a = Node(id: "1", position: .zero, data: "A")
        let b = Node(id: "1", position: .zero, data: "A")
        let c = Node(id: "2", position: .zero, data: "A")
        #expect(a == b)
        #expect(a != c)
    }

    @Test func codableRoundTrip() throws {
        let node = Node(id: "n1", position: XYPosition(x: 10, y: 20), data: "test",
                        type: "custom", selected: true, zIndex: 3)
        let data = try JSONEncoder().encode(node)
        let decoded = try JSONDecoder().decode(Node<String>.self, from: data)
        #expect(decoded.id == "n1")
        #expect(decoded.position == XYPosition(x: 10, y: 20))
        #expect(decoded.data == "test")
        #expect(decoded.type == "custom")
        #expect(decoded.selected == true)
        #expect(decoded.zIndex == 3)
        #expect(decoded.extent == nil) // Not coded
    }

    @Test func codableDefaults() throws {
        let json = """
        {"id": "1", "position": {"x": 0, "y": 0}, "data": "hello"}
        """
        let node = try JSONDecoder().decode(Node<String>.self, from: json.data(using: .utf8)!)
        #expect(node.type == "default")
        #expect(node.selected == false)
        #expect(node.draggable == true)
        #expect(node.deletable == true)
        #expect(node.zIndex == 0)
    }

    @Test func hashable() {
        let a = Node(id: "1", position: .zero, data: "A")
        let b = Node(id: "1", position: .zero, data: "A")
        var set: Set<Node<String>> = []
        set.insert(a)
        set.insert(b)
        #expect(set.count == 1)
    }

    @Test func mutableProperties() {
        var node = Node(id: "1", position: .zero, data: "A")
        node.position = XYPosition(x: 100, y: 200)
        node.selected = true
        node.hidden = true
        #expect(node.position.x == 100)
        #expect(node.selected == true)
        #expect(node.hidden == true)
    }
}
