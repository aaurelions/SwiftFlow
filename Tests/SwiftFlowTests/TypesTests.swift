import Testing
import Foundation
@testable import SwiftFlow

@Suite("Types")
struct TypesTests {

    // MARK: - HandleType

    @Test func handleTypeValues() {
        #expect(HandleType.source.rawValue == "source")
        #expect(HandleType.target.rawValue == "target")
    }

    // MARK: - Position

    @Test func positionValues() {
        #expect(Position.top.rawValue == "top")
        #expect(Position.bottom.rawValue == "bottom")
        #expect(Position.left.rawValue == "left")
        #expect(Position.right.rawValue == "right")
    }

    @Test func positionCodable() throws {
        let pos = Position.right
        let data = try JSONEncoder().encode(pos)
        let decoded = try JSONDecoder().decode(Position.self, from: data)
        #expect(decoded == pos)
    }

    // MARK: - NodeOrigin

    @Test func nodeOriginTopLeft() {
        let origin = NodeOrigin.topLeft
        #expect(origin.x == 0)
        #expect(origin.y == 0)
    }

    @Test func nodeOriginCenter() {
        let origin = NodeOrigin.center
        #expect(origin.x == 0.5)
        #expect(origin.y == 0.5)
    }

    // MARK: - ConnectionMode

    @Test func connectionModes() {
        #expect(ConnectionMode.strict.rawValue == "strict")
        #expect(ConnectionMode.loose.rawValue == "loose")
    }

    // MARK: - SelectionMode

    @Test func selectionModes() {
        #expect(SelectionMode.partial.rawValue == "partial")
        #expect(SelectionMode.full.rawValue == "full")
    }

    // MARK: - ColorMode

    @Test func colorModes() {
        _ = ColorMode.light
        _ = ColorMode.dark
        _ = ColorMode.system
    }

    // MARK: - ZIndexMode

    @Test func zIndexModes() {
        _ = ZIndexMode.auto
        _ = ZIndexMode.basic
        _ = ZIndexMode.manual
    }

    // MARK: - BackgroundVariant

    @Test func backgroundVariants() {
        _ = BackgroundVariant.dots
        _ = BackgroundVariant.lines
        _ = BackgroundVariant.cross
    }

    // MARK: - PanOnScrollMode

    @Test func panOnScrollModes() {
        _ = PanOnScrollMode.free
        _ = PanOnScrollMode.vertical
        _ = PanOnScrollMode.horizontal
    }

    // MARK: - NodeHandle

    @Test func nodeHandleDefaults() {
        let handle = NodeHandle()
        #expect(handle.id == nil)
        #expect(handle.type == .source)
        #expect(handle.position == .right)
        #expect(handle.x == 0)
        #expect(handle.y == 0)
        #expect(handle.width == 12)
        #expect(handle.height == 12)
    }

    @Test func nodeHandleCustom() {
        let handle = NodeHandle(id: "h1", type: .target, position: .left, x: 5, y: 10, width: 20, height: 20)
        #expect(handle.id == "h1")
        #expect(handle.type == .target)
        #expect(handle.position == .left)
        #expect(handle.width == 20)
    }

    @Test func nodeHandleCodable() throws {
        let handle = NodeHandle(id: "h1", type: .source, position: .right)
        let data = try JSONEncoder().encode(handle)
        let decoded = try JSONDecoder().decode(NodeHandle.self, from: data)
        #expect(decoded == handle)
    }

    // MARK: - DefaultEdgeOptions

    @Test func defaultEdgeOptionsDefaults() {
        let opts = DefaultEdgeOptions()
        #expect(opts.type == .default)
        #expect(opts.animated == false)
        #expect(opts.markerStart == nil)
        #expect(opts.markerEnd == nil)
    }

    @Test func defaultEdgeOptionsCustom() {
        let opts = DefaultEdgeOptions(type: .smoothstep, animated: true, markerEnd: .arrowClosed)
        #expect(opts.type == .smoothstep)
        #expect(opts.animated == true)
        #expect(opts.markerEnd?.type == .arrowClosed)
    }

    // MARK: - FitViewOptions

    @Test func fitViewOptionsDefaults() {
        let opts = FitViewOptions()
        #expect(opts.padding == 80)
        #expect(opts.includeHiddenNodes == false)
        #expect(opts.maxZoom == 1.5)
        #expect(opts.duration == 0.3)
        #expect(opts.nodeIds == nil)
    }

    @Test func fitViewOptionsCustom() {
        let opts = FitViewOptions(padding: 50, maxZoom: 2.0, nodeIds: ["1", "2"])
        #expect(opts.padding == 50)
        #expect(opts.maxZoom == 2.0)
        #expect(opts.nodeIds == ["1", "2"])
    }

    // MARK: - KeyboardShortcuts

    @Test func keyboardShortcutsDefaults() {
        let ks = KeyboardShortcuts.default
        #expect(ks.nudgeDistance == 1)
        #expect(ks.shiftNudgeDistance == 10)
    }

    // MARK: - AccessibilityConfig

    @Test func accessibilityConfigDefaults() {
        let config = AccessibilityConfig.default
        #expect(config.nodeRoleDescription == "Graph node")
        #expect(config.edgeRoleDescription == "Graph edge")
        #expect(config.announceSelectionChanges == true)
    }

    // MARK: - BeforeDeleteResult

    @Test func beforeDeleteCancel() {
        let result: BeforeDeleteResult<String, EmptyEdgeData> = .cancel
        if case .cancel = result {
            // pass
        } else {
            Issue.record("Expected .cancel")
        }
    }

    @Test func beforeDeleteWithItems() {
        let nodes = [Node(id: "1", position: .zero, data: "A")]
        let edges = [Edge<EmptyEdgeData>(id: "e1", source: "1", target: "2")]
        let result: BeforeDeleteResult<String, EmptyEdgeData> = .delete(nodes: nodes, edges: edges)
        if case .delete(let n, let e) = result {
            #expect(n.count == 1)
            #expect(e.count == 1)
        } else {
            Issue.record("Expected .delete")
        }
    }

    // MARK: - OnConnectStartParams

    @Test func onConnectStartParams() {
        let params = OnConnectStartParams(nodeId: "1", handleId: "out", handleType: .source)
        #expect(params.nodeId == "1")
        #expect(params.handleId == "out")
        #expect(params.handleType == .source)
    }

    // MARK: - ConnectionState

    @Test func connectionStateInit() {
        let fromNode = AnyNodeSnapshot(from: Node(id: "1", position: .zero, data: "A"))
        let state = ConnectionState(
            isValid: nil,
            from: CGPoint(x: 100, y: 50),
            fromHandle: NodeHandle(id: "out", type: .source),
            fromPosition: .right,
            fromNode: fromNode,
            to: CGPoint(x: 300, y: 150)
        )
        #expect(state.isValid == nil)
        #expect(state.from == CGPoint(x: 100, y: 50))
        #expect(state.to == CGPoint(x: 300, y: 150))
        #expect(state.fromHandle.id == "out")
        #expect(state.toHandle == nil)
        #expect(state.toNode == nil)
    }

    @Test func connectionStateEquatable() {
        let fromNode = AnyNodeSnapshot(from: Node(id: "1", position: .zero, data: "A"))
        let a = ConnectionState(
            from: .zero, fromHandle: NodeHandle(), fromPosition: .right, fromNode: fromNode, to: .zero)
        let b = ConnectionState(
            from: .zero, fromHandle: NodeHandle(), fromPosition: .right, fromNode: fromNode, to: .zero)
        #expect(a == b)
    }

    // MARK: - EdgePathResult

    @Test func edgePathResultInit() {
        let result = EdgePathResult(
            path: .init(), labelX: 100, labelY: 50,
            sourceX: 0, sourceY: 0, targetX: 200, targetY: 100)
        #expect(result.labelX == 100)
        #expect(result.labelY == 50)
        #expect(result.sourceX == 0)
        #expect(result.targetX == 200)
    }

    // MARK: - KeyCode

    @Test func keyCodeConstants() {
        #expect(KeyCode.backspace.rawValue == 51)
        #expect(KeyCode.forwardDelete.rawValue == 117)
        #expect(KeyCode.escape.rawValue == 53)
        #expect(KeyCode.return.rawValue == 36)
        #expect(KeyCode.tab.rawValue == 48)
        #expect(KeyCode.space.rawValue == 49)
    }

    @Test func keyCodeArrowKeys() {
        #expect(KeyCode.leftArrow.rawValue == 123)
        #expect(KeyCode.rightArrow.rawValue == 124)
        #expect(KeyCode.downArrow.rawValue == 125)
        #expect(KeyCode.upArrow.rawValue == 126)
    }

    @Test func keyCodeEquatable() {
        #expect(KeyCode.backspace == KeyCode(51))
        #expect(KeyCode.escape != KeyCode.return)
    }

    @Test func keyCodeHashable() {
        let set: Set<KeyCode> = [.backspace, .escape, .return, .backspace]
        #expect(set.count == 3)
    }

    @Test func keyCodeIntegerLiteral() {
        let code: KeyCode = 51
        #expect(code == KeyCode.backspace)
    }

    @Test func keyCodeLetterKeys() {
        #expect(KeyCode.a.rawValue == 0)
        #expect(KeyCode.c.rawValue == 8)
        #expect(KeyCode.v.rawValue == 9)
        #expect(KeyCode.x.rawValue == 7)
        #expect(KeyCode.z.rawValue == 6)
    }

    @Test func keyCodeModifierKeys() {
        #expect(KeyCode.command.rawValue == 55)
        #expect(KeyCode.shift.rawValue == 56)
        #expect(KeyCode.option.rawValue == 58)
        #expect(KeyCode.control.rawValue == 59)
    }

    // MARK: - ConnectionLineType

    @Test func connectionLineTypeIsEdgeType() {
        let lineType: ConnectionLineType = .smoothstep
        let edgeType: EdgeType = .smoothstep
        #expect(lineType == edgeType) // They're the same type
    }

    // MARK: - NodeStyle / EdgeStyle

    @Test func nodeStyleInit() {
        let style = NodeStyle(borderWidth: 2, borderRadius: 8, opacity: 0.8)
        #expect(style.borderWidth == 2)
        #expect(style.borderRadius == 8)
        #expect(style.opacity == 0.8)
        #expect(style.backgroundColor == nil)
        #expect(style.borderColor == nil)
    }

    @Test func edgeStyleInit() {
        let style = EdgeStyle(strokeWidth: 3, opacity: 0.5)
        #expect(style.strokeWidth == 3)
        #expect(style.opacity == 0.5)
        #expect(style.strokeColor == nil)
    }
}
