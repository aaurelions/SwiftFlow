import Testing
import Foundation
@testable import SwiftFlow

@Suite("NodeExtent")
struct NodeExtentTests {

    @Test func parentVariant() {
        let extent: NodeExtent = .parent
        #expect(extent == .parent)
    }

    @Test func coordinateExtentVariant() {
        let ce = CoordinateExtent(minX: 0, minY: 0, maxX: 500, maxY: 500)
        let extent: NodeExtent = .coordinateExtent(ce)
        if case .coordinateExtent(let inner) = extent {
            #expect(inner == ce)
        } else {
            Issue.record("Expected .coordinateExtent")
        }
    }

    @Test func equatable() {
        let a: NodeExtent = .parent
        let b: NodeExtent = .parent
        let c: NodeExtent = .coordinateExtent(CoordinateExtent(minX: 0, minY: 0, maxX: 100, maxY: 100))
        #expect(a == b)
        #expect(a != c)
    }

    @Test func hashable() {
        var set: Set<NodeExtent> = []
        set.insert(.parent)
        set.insert(.parent)
        #expect(set.count == 1)
        set.insert(.coordinateExtent(.infinite))
        #expect(set.count == 2)
    }

    @Test func nodeWithParentExtent() {
        let node = Node(id: "1", position: .zero, data: "x", parentId: "group", extent: .parent)
        #expect(node.extent == .parent)
    }
}
