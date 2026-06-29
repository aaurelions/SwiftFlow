import Testing
import Foundation
@testable import SwiftFlow

@Suite("Viewport")
struct ViewportTests {

    @Test func identity() {
        let vp = Viewport.identity
        #expect(vp.x == 0)
        #expect(vp.y == 0)
        #expect(vp.zoom == 1)
    }

    @Test func initWithDefaults() {
        let vp = Viewport()
        #expect(vp.x == 0)
        #expect(vp.y == 0)
        #expect(vp.zoom == 1)
    }

    @Test func initWithCustomValues() {
        let vp = Viewport(x: 100, y: 200, zoom: 2.0)
        #expect(vp.x == 100)
        #expect(vp.y == 200)
        #expect(vp.zoom == 2.0)
    }

    @Test func clampedZoomWithinRange() {
        let vp = Viewport(zoom: 1.5)
        #expect(vp.clampedZoom == 1.5)
    }

    @Test func clampedZoomBelowMin() {
        let vp = Viewport(zoom: 0.01)
        #expect(vp.clampedZoom == Viewport.minZoom)
    }

    @Test func clampedZoomAboveMax() {
        let vp = Viewport(zoom: 10.0)
        #expect(vp.clampedZoom == Viewport.maxZoom)
    }

    @Test func zoomBounds() {
        #expect(Viewport.minZoom == 0.1)
        #expect(Viewport.maxZoom == 4.0)
    }

    @Test func equatable() {
        let a = Viewport(x: 1, y: 2, zoom: 1.5)
        let b = Viewport(x: 1, y: 2, zoom: 1.5)
        let c = Viewport(x: 1, y: 2, zoom: 2.0)
        #expect(a == b)
        #expect(a != c)
    }

    @Test func codable() throws {
        let vp = Viewport(x: 10, y: 20, zoom: 2.5)
        let data = try JSONEncoder().encode(vp)
        let decoded = try JSONDecoder().decode(Viewport.self, from: data)
        #expect(decoded == vp)
    }

    @Test func hashable() {
        let a = Viewport(x: 1, y: 2, zoom: 1.5)
        let b = Viewport(x: 1, y: 2, zoom: 1.5)
        var set: Set<Viewport> = []
        set.insert(a)
        set.insert(b)
        #expect(set.count == 1)
    }
}
