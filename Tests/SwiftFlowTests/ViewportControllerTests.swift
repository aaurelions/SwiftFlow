import Testing
import Foundation
@testable import SwiftFlow

@Suite("ViewportController")
struct ViewportControllerTests {

    @MainActor
    @Test func initDefaults() {
        let instance = SwiftFlowInstance()
        #expect(instance.viewport == .identity)
        #expect(instance.viewSize == .zero)
        #expect(instance.nodeSizes.isEmpty)
    }

    @MainActor
    @Test func getViewport() {
        let instance = SwiftFlowInstance()
        instance.viewport = Viewport(x: 10, y: 20, zoom: 1.5)
        #expect(instance.getViewport() == Viewport(x: 10, y: 20, zoom: 1.5))
    }

    @MainActor
    @Test func setViewport() {
        let instance = SwiftFlowInstance()
        let newVp = Viewport(x: 100, y: 200, zoom: 2.0)
        instance.setViewport(newVp, animated: false)
        #expect(instance.viewport == newVp)
    }

    @MainActor
    @Test func setViewportTriggersCallback() {
        let instance = SwiftFlowInstance()
        var receivedViewport: Viewport?
        instance.onViewportChange = { vp in receivedViewport = vp }
        instance.setViewport(Viewport(x: 50, y: 60, zoom: 1.5), animated: false)
        #expect(receivedViewport != nil)
    }

    @MainActor
    @Test func reset() {
        let instance = SwiftFlowInstance()
        instance.viewport = Viewport(x: 100, y: 200, zoom: 2.0)
        instance.reset(animated: false)
        #expect(instance.viewport == .identity)
    }

    @MainActor
    @Test func screenToFlowPosition() {
        let instance = SwiftFlowInstance()
        instance.viewport = Viewport(x: 100, y: 50, zoom: 2.0)
        let flowPos = instance.screenToFlowPosition(CGPoint(x: 200, y: 150))
        #expect(flowPos.x == 50)  // (200 - 100) / 2
        #expect(flowPos.y == 50)  // (150 - 50) / 2
    }

    @MainActor
    @Test func flowToScreenPosition() {
        let instance = SwiftFlowInstance()
        instance.viewport = Viewport(x: 100, y: 50, zoom: 2.0)
        let screenPos = instance.flowToScreenPosition(CGPoint(x: 50, y: 50))
        #expect(screenPos.x == 200) // 50 * 2 + 100
        #expect(screenPos.y == 150) // 50 * 2 + 50
    }

    @MainActor
    @Test func coordinateConversionRoundTrip() {
        let instance = SwiftFlowInstance()
        instance.viewport = Viewport(x: 73, y: -45, zoom: 1.7)
        let original = CGPoint(x: 123.4, y: 567.8)
        let screen = instance.flowToScreenPosition(original)
        let flow = instance.screenToFlowPosition(screen)
        #expect(abs(flow.x - original.x) < 0.001)
        #expect(abs(flow.y - original.y) < 0.001)
    }

    @MainActor
    @Test func zoomTo() {
        let instance = SwiftFlowInstance()
        instance.viewport = Viewport(x: 0, y: 0, zoom: 1.0)
        instance.viewSize = CGSize(width: 800, height: 600)
        instance.zoomTo(2.0, animated: false)
        #expect(instance.viewport.zoom == 2.0)
    }

    @MainActor
    @Test func zoomIn() {
        let instance = SwiftFlowInstance()
        instance.viewport = Viewport(x: 0, y: 0, zoom: 1.0)
        instance.viewSize = CGSize(width: 800, height: 600)
        instance.zoomIn(animated: false)
        #expect(instance.viewport.zoom == 1.25)
    }

    @MainActor
    @Test func zoomOut() {
        let instance = SwiftFlowInstance()
        instance.viewport = Viewport(x: 0, y: 0, zoom: 1.0)
        instance.viewSize = CGSize(width: 800, height: 600)
        instance.zoomOut(animated: false)
        #expect(instance.viewport.zoom == 0.8)
    }

    @MainActor
    @Test func setCenter() {
        let instance = SwiftFlowInstance()
        instance.viewSize = CGSize(width: 800, height: 600)
        instance.setCenter(x: 100, y: 200, zoom: 1.0, animated: false)
        // Center should be at flow point (100, 200)
        let center = instance.screenToFlowPosition(
            CGPoint(x: instance.viewSize.width / 2, y: instance.viewSize.height / 2)
        )
        #expect(abs(center.x - 100) < 0.1)
        #expect(abs(center.y - 200) < 0.1)
    }

    @MainActor
    @Test func getNodesBounds() {
        let instance = SwiftFlowInstance()
        let nodes = [
            Node(id: "1", position: XYPosition(x: 0, y: 0), data: "A"),
            Node(id: "2", position: XYPosition(x: 200, y: 100), data: "B"),
        ]
        let sizes: [String: CGSize] = [
            "1": CGSize(width: 100, height: 50),
            "2": CGSize(width: 100, height: 50),
        ]
        let bounds = instance.getNodesBounds(nodes: nodes, nodeSizes: sizes)
        #expect(bounds.minX == 0)
        #expect(bounds.minY == 0)
        #expect(bounds.width == 300)
        #expect(bounds.height == 150)
    }

    @MainActor
    @Test func getViewportForBounds() {
        let instance = SwiftFlowInstance()
        instance.viewSize = CGSize(width: 800, height: 600)
        let bounds = CGRect(x: 0, y: 0, width: 400, height: 200)
        let vp = instance.getViewportForBounds(bounds: bounds, padding: 80)
        #expect(vp.zoom > 0)
        #expect(vp.zoom <= Viewport.maxZoom)
    }

    @MainActor
    @Test func zoomToClamp() {
        let instance = SwiftFlowInstance()
        instance.viewport = Viewport(x: 0, y: 0, zoom: 1.0)
        instance.viewSize = CGSize(width: 800, height: 600)
        instance.zoomTo(100.0, animated: false) // Way above max
        #expect(instance.viewport.zoom == Viewport.maxZoom)
    }

    @MainActor
    @Test func fitView() {
        let instance = SwiftFlowInstance()
        instance.viewSize = CGSize(width: 800, height: 600)
        let nodes = [
            Node(id: "1", position: XYPosition(x: 0, y: 0), data: "A"),
            Node(id: "2", position: XYPosition(x: 200, y: 100), data: "B"),
        ]
        let sizes: [String: CGSize] = [
            "1": CGSize(width: 100, height: 50),
            "2": CGSize(width: 100, height: 50),
        ]
        instance.fitView(nodes: nodes, nodeSizes: sizes)
        #expect(instance.viewport.zoom > 0)
        #expect(instance.viewport.zoom <= 1.5) // default maxZoom
    }

    @MainActor
    @Test func fitViewWithNodeIds() {
        let instance = SwiftFlowInstance()
        instance.viewSize = CGSize(width: 800, height: 600)
        let nodes = [
            Node(id: "1", position: XYPosition(x: 0, y: 0), data: "A"),
            Node(id: "2", position: XYPosition(x: 500, y: 500), data: "B"),
        ]
        let sizes: [String: CGSize] = [
            "1": CGSize(width: 100, height: 50),
            "2": CGSize(width: 100, height: 50),
        ]
        let optionsAll = FitViewOptions()
        instance.fitView(nodes: nodes, nodeSizes: sizes, options: optionsAll)
        let vpAll = instance.viewport

        instance.viewport = .identity
        let optionsSubset = FitViewOptions(nodeIds: ["1"])
        instance.fitView(nodes: nodes, nodeSizes: sizes, options: optionsSubset)
        let vpSubset = instance.viewport

        // Subset should have different zoom since it frames fewer nodes
        #expect(vpSubset.zoom != vpAll.zoom || vpSubset.x != vpAll.x)
    }

    @MainActor
    @Test func fitViewHiddenIncluded() {
        let instance = SwiftFlowInstance()
        instance.viewSize = CGSize(width: 800, height: 600)
        let nodes = [
            Node(id: "1", position: XYPosition(x: 0, y: 0), data: "A"),
            Node(id: "2", position: XYPosition(x: 500, y: 500), data: "B", hidden: true),
        ]
        let sizes: [String: CGSize] = [
            "1": CGSize(width: 100, height: 50),
            "2": CGSize(width: 100, height: 50),
        ]
        let options = FitViewOptions(includeHiddenNodes: true)
        instance.fitView(nodes: nodes, nodeSizes: sizes, options: options)
        #expect(instance.viewport.zoom > 0)
    }

    @MainActor
    @Test func fitViewEmpty() {
        let instance = SwiftFlowInstance()
        instance.viewSize = CGSize(width: 800, height: 600)
        let nodes: [Node<String>] = []
        instance.fitView(nodes: nodes, nodeSizes: [:])
        #expect(instance.viewport == .identity) // No change
    }

    @MainActor
    @Test func deleteElements() {
        let instance = SwiftFlowInstance()
        var removedEdgeIds: [Any]?
        instance._applyEdgeChanges = { changes in removedEdgeIds = changes }
        instance.deleteElements(edgeIds: ["e1", "e2"])
        #expect(removedEdgeIds != nil)
    }
}
