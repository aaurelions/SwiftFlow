import Foundation
import SwiftUI
import Testing

@testable import SwiftFlow

@Suite("Accessibility")
struct AccessibilityTests {

  @Test func defaultStringsComeFromTheCatalog() {
    let config = AccessibilityConfig()
    #expect(config.nodeRoleDescription == "Graph node")
    #expect(config.zoomInAriaLabel == "Zoom in")
    #expect(config.handleAriaLabel == "Drag to create a connection")
  }

  @Test func selectionAnnouncementUsesPluralRules() {
    let announce = AccessibilityConfig.default.selectionAnnouncement
    #expect(announce(0, 0) == "Selection cleared")
    #expect(announce(1, 0) == "1 node selected")
    #expect(announce(3, 0) == "3 nodes selected")
    #expect(announce(0, 1) == "1 edge selected")
    #expect(announce(1, 2) == "1 node and 2 edges selected")
    #expect(announce(2, 1) == "2 nodes and 1 edge selected")
  }

  @Test func connectionAnnouncementNamesBothNodes() {
    let message = AccessibilityConfig.default.connectionAnnouncement(
      Connection(source: "a", target: "b"))
    #expect(message == "Connected a to b")
  }

  @Test func customStringsAndMessagesOverrideDefaults() {
    let config = AccessibilityConfig(
      nodeRoleDescription: "Step",
      selectionAnnouncement: { nodes, edges in "\(nodes)/\(edges)" },
      connectionAnnouncement: { "\($0.source)->\($0.target)" })
    #expect(config.nodeRoleDescription == "Step")
    #expect(config.edgeRoleDescription == "Graph edge")
    #expect(config.selectionAnnouncement(2, 3) == "2/3")
    #expect(config.connectionAnnouncement(Connection(source: "x", target: "y")) == "x->y")
  }

  @Test func equalityComparesStringsAndIgnoresClosures() {
    let custom = AccessibilityConfig(selectionAnnouncement: { _, _ in "custom" })
    #expect(custom == .default)
    #expect(AccessibilityConfig(zoomInAriaLabel: "Bigger") != .default)
  }
}

@Suite("Resize")
struct ResizeTests {

  private func event(
    from start: CGSize, to size: CGSize, left: Bool = false, top: Bool = false
  ) -> NodeResizeEvent {
    NodeResizeEvent(
      nodeId: "n", phase: .change, startSize: start, size: size,
      movesLeftEdge: left, movesTopEdge: top)
  }

  @Test func bottomRightHandleKeepsTopLeftCorner() {
    let offset = resizePositionOffset(
      for: event(from: CGSize(width: 100, height: 50), to: CGSize(width: 150, height: 80)),
      origin: .topLeft)
    #expect(offset == .zero)
  }

  @Test func topLeftHandleMovesPositionByTheGrowth() {
    let offset = resizePositionOffset(
      for: event(
        from: CGSize(width: 100, height: 50), to: CGSize(width: 150, height: 80),
        left: true, top: true),
      origin: .topLeft)
    #expect(offset == XYPosition(x: -50, y: -30))
  }

  @Test func centeredNodesKeepTheOppositeEdge() {
    let start = CGSize(width: 100, height: 50)
    let wider = CGSize(width: 150, height: 50)
    // Right handle: the left edge stays, so the center moves right by half the growth.
    #expect(
      resizePositionOffset(for: event(from: start, to: wider), origin: .center)
        == XYPosition(x: 25, y: 0))
    // Left handle: the right edge stays, so the center moves left by half the growth.
    #expect(
      resizePositionOffset(for: event(from: start, to: wider, left: true), origin: .center)
        == XYPosition(x: -25, y: 0))
  }
}

@Suite("ExpandParent")
struct ExpandParentTests {
  private let sizes: [String: CGSize] = [
    "p": CGSize(width: 200, height: 100),
    "c": CGSize(width: 50, height: 50),
    "s": CGSize(width: 10, height: 10),
  ]

  private func graph(expandParent: Bool = true) -> [Node<String>] {
    [
      Node(id: "p", position: XYPosition(x: 100, y: 100), data: "P"),
      Node(
        id: "c", position: XYPosition(x: 10, y: 10), data: "C", parentId: "p",
        expandParent: expandParent),
      Node(id: "s", position: XYPosition(x: 20, y: 20), data: "S", parentId: "p"),
    ]
  }

  @Test func childInsideParentChangesNothing() {
    let result = expandParentChanges(
      nodes: graph(), movedIds: ["c"], positions: ["c": XYPosition(x: 40, y: 20)],
      nodeSizes: sizes)
    #expect(result.changes.isEmpty)
    #expect(result.shifts.isEmpty)
  }

  @Test func draggingPastBottomRightGrowsTheParent() {
    let result = expandParentChanges(
      nodes: graph(), movedIds: ["c"], positions: ["c": XYPosition(x: 180, y: 80)],
      nodeSizes: sizes)
    #expect(result.shifts.isEmpty)
    guard case .dimensions(let id, let width, let height) = result.changes.first else {
      Issue.record("Expected a dimensions change")
      return
    }
    #expect(id == "p" && width == 230 && height == 130)
    #expect(result.changes.count == 1)
  }

  @Test func draggingPastTopLeftMovesParentAndShiftsChildren() {
    let result = expandParentChanges(
      nodes: graph(), movedIds: ["c"], positions: ["c": XYPosition(x: -30, y: -10)],
      nodeSizes: sizes)
    #expect(result.shifts == ["c": XYPosition(x: 30, y: 10)])
    var dimensions: CGSize?
    var positions: [String: XYPosition] = [:]
    for change in result.changes {
      switch change {
      case .dimensions(_, let width, let height): dimensions = CGSize(width: width, height: height)
      case .position(let id, let position): positions[id] = position
      default: Issue.record("Unexpected change \(change)")
      }
    }
    #expect(dimensions == CGSize(width: 230, height: 110))
    #expect(positions["p"] == XYPosition(x: 70, y: 90))
    // The unmoved sibling keeps its place in flow coordinates: 70 + 50 = 100 + 20.
    #expect(positions["s"] == XYPosition(x: 50, y: 30))
  }

  @Test func nodesWithoutExpandParentAreIgnored() {
    let result = expandParentChanges(
      nodes: graph(expandParent: false), movedIds: ["c"],
      positions: ["c": XYPosition(x: 500, y: 500)], nodeSizes: sizes)
    #expect(result.changes.isEmpty)
  }
}

@Suite("KeyboardFocus")
struct KeyboardFocusTests {

  @MainActor
  @Test func focusOrderListsVisibleFocusableNodesThenEdges() {
    let nodes = [
      Node(id: "a", position: .zero, data: "A"),
      Node(id: "hidden", position: .zero, data: "H", hidden: true),
      Node(id: "b", position: .zero, data: "B", focusable: false),
      Node(id: "c", position: .zero, data: "C"),
    ]
    let edges = [
      FlowEdge<EmptyEdgeData>(id: "e1", source: "a", target: "c"),
      FlowEdge<EmptyEdgeData>(id: "e2", source: "c", target: "a", focusable: false),
    ]
    let flow = SwiftFlow(nodes: nodes, edges: edges) { _ in EmptyView() }
    #expect(flow.focusOrder == [.node("a"), .node("c"), .edge("e1")])
  }

  @Test func canvasKeysRequireAnActiveCanvasAndNoTextEditing() {
    #expect(
      canvasShouldHandleKey(isCanvasActive: true, isInCanvasWindow: true, isEditingText: false))
    #expect(
      !canvasShouldHandleKey(isCanvasActive: false, isInCanvasWindow: true, isEditingText: false))
    #expect(
      !canvasShouldHandleKey(isCanvasActive: true, isInCanvasWindow: false, isEditingText: false))
    #expect(
      !canvasShouldHandleKey(isCanvasActive: true, isInCanvasWindow: true, isEditingText: true))
  }
}

#if canImport(AppKit)
  import AppKit

  /// Dispatches real events through `NSApplication` to the canvas key monitor.
  @Suite("KeyMonitor", .serialized)
  @MainActor
  struct KeyMonitorTests {
    private func makeWindow() -> (NSWindow, KeyDownHandler.KeyMonitorView) {
      _ = NSApplication.shared
      let window = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 200, height: 200), styleMask: [.titled],
        backing: .buffered, defer: false)
      window.isReleasedWhenClosed = false
      let monitor = KeyDownHandler.KeyMonitorView(
        frame: NSRect(x: 0, y: 0, width: 100, height: 200))
      window.contentView?.addSubview(monitor)
      return (window, monitor)
    }

    private func mouseDown(at point: NSPoint, in window: NSWindow) -> NSEvent {
      NSEvent.mouseEvent(
        with: .leftMouseDown, location: point, modifierFlags: [], timestamp: 0,
        windowNumber: window.windowNumber, context: nil, eventNumber: 0, clickCount: 1,
        pressure: 1)!
    }

    private func keyDown(_ keyCode: UInt16, in window: NSWindow) -> NSEvent {
      NSEvent.keyEvent(
        with: .keyDown, location: .zero, modifierFlags: [], timestamp: 0,
        windowNumber: window.windowNumber, context: nil, characters: "\t",
        charactersIgnoringModifiers: "\t", isARepeat: false, keyCode: keyCode)!
    }

    @Test func keysReachTheCanvasOnlyAfterClickingInsideIt() {
      let (window, monitor) = makeWindow()
      defer { window.close() }
      var received: [UInt16] = []
      monitor.handler = { event in
        received.append(event.keyCode)
        return true
      }

      NSApp.sendEvent(keyDown(KeyCode.tab.rawValue, in: window))
      #expect(received.isEmpty)  // No click yet.

      NSApp.sendEvent(mouseDown(at: NSPoint(x: 50, y: 50), in: window))
      #expect(monitor.isCanvasActive)
      NSApp.sendEvent(keyDown(KeyCode.tab.rawValue, in: window))
      #expect(received == [KeyCode.tab.rawValue])

      // A click outside the canvas (right half of the window) deactivates it.
      NSApp.sendEvent(mouseDown(at: NSPoint(x: 150, y: 50), in: window))
      #expect(!monitor.isCanvasActive)
      NSApp.sendEvent(keyDown(KeyCode.tab.rawValue, in: window))
      #expect(received.count == 1)
    }

    @Test func keysGoToTextFieldsBeingEdited() {
      let (window, monitor) = makeWindow()
      defer { window.close() }
      var received = 0
      monitor.handler = { _ in
        received += 1
        return true
      }
      let field = NSTextField(frame: NSRect(x: 110, y: 10, width: 80, height: 24))
      window.contentView?.addSubview(field)

      NSApp.sendEvent(mouseDown(at: NSPoint(x: 50, y: 50), in: window))
      window.makeFirstResponder(field)  // Starts editing with the field editor (an NSText).
      #expect(window.firstResponder is NSText)
      NSApp.sendEvent(keyDown(KeyCode.backspace.rawValue, in: window))
      #expect(received == 0)
    }
  }
#endif
