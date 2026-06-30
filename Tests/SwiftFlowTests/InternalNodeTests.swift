import Foundation
import Testing

@testable import SwiftFlow

@Suite("InternalNode")
struct InternalNodeTests {

  @Test func initFromNode() {
    let node = Node(id: "1", position: XYPosition(x: 10, y: 20), data: "Hello")
    let internalNode = InternalNode(
      node: node,
      absolutePosition: XYPosition(x: 100, y: 200),
      measuredWidth: 300,
      measuredHeight: 150
    )
    #expect(internalNode.id == "1")
    #expect(internalNode.node.data == "Hello")
    #expect(internalNode.absolutePosition.x == 100)
    #expect(internalNode.measuredWidth == 300)
    #expect(internalNode.measuredHeight == 150)
  }

  @Test func initDefaults() {
    let node = Node(id: "1", position: .zero, data: "A")
    let internalNode = InternalNode(node: node)
    #expect(internalNode.absolutePosition == .zero)
    #expect(internalNode.measuredWidth == nil)
    #expect(internalNode.measuredHeight == nil)
  }

  @Test func equatable() {
    let node = Node(id: "1", position: .zero, data: "A")
    let a = InternalNode(
      node: node, absolutePosition: .zero, measuredWidth: 100, measuredHeight: 50)
    let b = InternalNode(
      node: node, absolutePosition: .zero, measuredWidth: 100, measuredHeight: 50)
    let c = InternalNode(
      node: node, absolutePosition: XYPosition(x: 10, y: 0), measuredWidth: 100, measuredHeight: 50)
    #expect(a == b)
    #expect(a != c)
  }
}
