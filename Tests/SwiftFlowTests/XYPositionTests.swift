import Foundation
import Testing

@testable import SwiftFlow

@Suite("XYPosition")
struct XYPositionTests {

  @Test func zero() {
    let pos = XYPosition.zero
    #expect(pos.x == 0)
    #expect(pos.y == 0)
  }

  @Test func initWithValues() {
    let pos = XYPosition(x: 10, y: 20)
    #expect(pos.x == 10)
    #expect(pos.y == 20)
  }

  @Test func addition() {
    let a = XYPosition(x: 10, y: 20)
    let b = XYPosition(x: 5, y: 15)
    let result = a + b
    #expect(result.x == 15)
    #expect(result.y == 35)
  }

  @Test func subtraction() {
    let a = XYPosition(x: 10, y: 20)
    let b = XYPosition(x: 5, y: 15)
    let result = a - b
    #expect(result.x == 5)
    #expect(result.y == 5)
  }

  @Test func snappedToGrid() {
    let pos = XYPosition(x: 17, y: 33)
    let snapped = pos.snapped(to: (x: 10, y: 10))
    #expect(snapped.x == 20)
    #expect(snapped.y == 30)
  }

  @Test func snappedToGridExact() {
    let pos = XYPosition(x: 20, y: 30)
    let snapped = pos.snapped(to: (x: 10, y: 10))
    #expect(snapped.x == 20)
    #expect(snapped.y == 30)
  }

  @Test func snappedNegativeValues() {
    let pos = XYPosition(x: -17, y: -33)
    let snapped = pos.snapped(to: (x: 10, y: 10))
    #expect(snapped.x == -20)
    #expect(snapped.y == -30)
  }

  @Test func equatable() {
    let a = XYPosition(x: 10, y: 20)
    let b = XYPosition(x: 10, y: 20)
    let c = XYPosition(x: 10, y: 21)
    #expect(a == b)
    #expect(a != c)
  }

  @Test func codable() throws {
    let pos = XYPosition(x: 42.5, y: 99.1)
    let data = try JSONEncoder().encode(pos)
    let decoded = try JSONDecoder().decode(XYPosition.self, from: data)
    #expect(decoded == pos)
  }

  @Test func hashable() {
    let a = XYPosition(x: 10, y: 20)
    let b = XYPosition(x: 10, y: 20)
    var set: Set<XYPosition> = []
    set.insert(a)
    set.insert(b)
    #expect(set.count == 1)
  }
}
