import Foundation
import Testing

@testable import SwiftFlow

@Suite("MiniMap geometry")
struct MiniMapTests {
  @Test func visibleCanvasFitsAtEveryZoomAndPan() {
    let mapSize = CGSize(width: 150, height: 100)
    let viewSize = CGSize(width: 1200, height: 800)
    for zoom: CGFloat in [0.1, 1, 4] {
      for offset: CGFloat in [-3000, 0, 3000] {
        let viewport = Viewport(x: offset, y: -offset, zoom: zoom)
        let graph = CGRect(x: -100, y: 70, width: 400, height: 200)
        let layout = MiniMapLayout(
          nodeRects: [graph], viewport: viewport,
          viewSize: viewSize, mapSize: mapSize, padding: 20)
        let visible = CGRect(
          x: -viewport.x / zoom, y: -viewport.y / zoom,
          width: viewSize.width / zoom, height: viewSize.height / zoom)
        #expect(layout.bounds.contains(graph))
        #expect(layout.bounds.contains(visible))
        let right = layout.padding + (visible.maxX - layout.bounds.minX) * layout.scale
        let bottom = layout.padding + (visible.maxY - layout.bounds.minY) * layout.scale
        #expect(right <= mapSize.width - layout.padding + 0.001)
        #expect(bottom <= mapSize.height - layout.padding + 0.001)
      }
    }
  }

  @Test func clickMapsBackToFlowAtLowZoom() {
    let layout = MiniMapLayout(
      nodeRects: [], viewport: Viewport(x: 230, y: -170, zoom: 0.1),
      viewSize: CGSize(width: 1200, height: 800), mapSize: CGSize(width: 150, height: 100),
      padding: 20)
    let target = CGPoint(x: 500, y: -700)
    let click = CGPoint(
      x: layout.padding + (target.x - layout.bounds.minX) * layout.scale,
      y: layout.padding + (target.y - layout.bounds.minY) * layout.scale)
    let result = layout.flowPosition(at: click)
    #expect(abs(result.x - target.x) < 0.001)
    #expect(abs(result.y - target.y) < 0.001)
  }

  @Test func emptyAndTinyMapsHaveUsableGeometry() {
    for size in [CGSize.zero, CGSize(width: 10, height: 10), CGSize(width: 150, height: 100)] {
      let layout = MiniMapLayout(
        nodeRects: [], viewport: .identity,
        viewSize: .zero, mapSize: size, padding: 20)
      #expect(layout.scale.isFinite && layout.scale > 0)
      let point = layout.flowPosition(at: .zero)
      #expect(point.x.isFinite && point.y.isFinite)
    }
  }
}
