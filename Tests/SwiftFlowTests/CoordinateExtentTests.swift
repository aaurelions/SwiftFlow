import Testing
import Foundation
@testable import SwiftFlow

@Suite("CoordinateExtent")
struct CoordinateExtentTests {

    @Test func infinite() {
        let ext = CoordinateExtent.infinite
        #expect(ext.minX == -.infinity)
        #expect(ext.minY == -.infinity)
        #expect(ext.maxX == .infinity)
        #expect(ext.maxY == .infinity)
    }

    @Test func clampWithinBounds() {
        let ext = CoordinateExtent(minX: 0, minY: 0, maxX: 100, maxY: 100)
        let pos = XYPosition(x: 50, y: 50)
        let clamped = ext.clamp(pos)
        #expect(clamped == pos)
    }

    @Test func clampBelowMin() {
        let ext = CoordinateExtent(minX: 0, minY: 0, maxX: 100, maxY: 100)
        let clamped = ext.clamp(XYPosition(x: -10, y: -20))
        #expect(clamped.x == 0)
        #expect(clamped.y == 0)
    }

    @Test func clampAboveMax() {
        let ext = CoordinateExtent(minX: 0, minY: 0, maxX: 100, maxY: 100)
        let clamped = ext.clamp(XYPosition(x: 150, y: 200))
        #expect(clamped.x == 100)
        #expect(clamped.y == 100)
    }

    @Test func clampInfinite() {
        let ext = CoordinateExtent.infinite
        let pos = XYPosition(x: 99999, y: -99999)
        let clamped = ext.clamp(pos)
        #expect(clamped == pos)
    }

    @Test func initFromArrays() {
        let ext = CoordinateExtent([[10, 20], [300, 400]])
        #expect(ext.minX == 10)
        #expect(ext.minY == 20)
        #expect(ext.maxX == 300)
        #expect(ext.maxY == 400)
    }

    @Test func equatable() {
        let a = CoordinateExtent(minX: 0, minY: 0, maxX: 100, maxY: 100)
        let b = CoordinateExtent(minX: 0, minY: 0, maxX: 100, maxY: 100)
        let c = CoordinateExtent(minX: 0, minY: 0, maxX: 200, maxY: 100)
        #expect(a == b)
        #expect(a != c)
    }
}
