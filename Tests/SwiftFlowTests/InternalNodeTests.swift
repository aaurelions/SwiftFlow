import Testing
import Foundation
@testable import SwiftFlow

@Suite("InternalNode")
struct InternalNodeTests {

    @Test func initFromNode() {
        let node = Node(id: "1", position: XYPosition(x: 10, y: 20), data: "Hello")
        let internal_ = InternalNode(
            node: node,
            absolutePosition: XYPosition(x: 100, y: 200),
            measuredWidth: 300,
            measuredHeight: 150
        )
        #expect(internal_.id == "1")
        #expect(internal_.node.data == "Hello")
        #expect(internal_.absolutePosition.x == 100)
        #expect(internal_.measuredWidth == 300)
        #expect(internal_.measuredHeight == 150)
    }

    @Test func initDefaults() {
        let node = Node(id: "1", position: .zero, data: "A")
        let internal_ = InternalNode(node: node)
        #expect(internal_.absolutePosition == .zero)
        #expect(internal_.measuredWidth == nil)
        #expect(internal_.measuredHeight == nil)
    }

    @Test func equatable() {
        let node = Node(id: "1", position: .zero, data: "A")
        let a = InternalNode(node: node, absolutePosition: .zero, measuredWidth: 100, measuredHeight: 50)
        let b = InternalNode(node: node, absolutePosition: .zero, measuredWidth: 100, measuredHeight: 50)
        let c = InternalNode(node: node, absolutePosition: XYPosition(x: 10, y: 0), measuredWidth: 100, measuredHeight: 50)
        #expect(a == b)
        #expect(a != c)
    }
}
