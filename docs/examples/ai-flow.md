# AI Flow — Project Setup & ContentView Demo

Build an interactive AI workflow editor with SwiftFlow. This example walks through creating a new SwiftUI project that depends on SwiftFlow and writing a complete `ContentView.swift` with nodes, edges, handles, and overlay components.

![AI Flow Demo Screenshot](/screenshot.png)

## Project Setup

### Add the SwiftFlow Package

Add SwiftFlow to your project via Xcode: **File → Add Package Dependencies...** and paste:

```
https://github.com/aaurelions/SwiftFlow.git
```

Choose version `0.1.0` or the latest release.

Alternatively, add it to your `Package.swift`:

```swift
// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "AI_FLOW",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/aaurelions/SwiftFlow.git", from: "0.1.0")
    ],
    targets: [
        .executableTarget(
            name: "AI_FLOW",
            dependencies: ["SwiftFlow"]
        )
    ]
)
```

## ContentView.swift

Create `ContentView.swift` with the following code. This builds an AI request flow editor with classified outputs:

```swift
import SwiftUI
import SwiftFlow
import UniformTypeIdentifiers
import JavaScriptCore

// MARK: - Color Constants

private extension Color {
    static let canvasBg = Color(red: 0.043, green: 0.055, blue: 0.078)
    static let nodeBg = Color(red: 0.075, green: 0.094, blue: 0.125)
    static let borderDim = Color(red: 0.165, green: 0.196, blue: 0.235)
    static let borderMid = Color(red: 0.122, green: 0.149, blue: 0.188)
    static let textMuted = Color(red: 0.353, green: 0.420, blue: 0.486)
    static let textBody = Color(red: 0.627, green: 0.678, blue: 0.753)
    static let cyanAccent = Color(red: 0, green: 0.898, blue: 1)
    static let greenAccent = Color(red: 0, green: 1, blue: 0.667)
    static let fieldBg = Color(red: 0.043, green: 0.055, blue: 0.078).opacity(0.6)
}

// MARK: - Node Type Definitions

enum FlowNodeType: String, CaseIterable, Sendable {
    case inputText, inputImage, customScript, httpRequest, jsonPath
    case outputText, outputImage
    case macroNode, macroInEdge, macroInParam, macroOutput, macroConnections

    var dimensions: CGSize {
        switch self {
        case .inputText:        return CGSize(width: 220, height: 140)
        case .inputImage:       return CGSize(width: 220, height: 140)
        case .customScript:     return CGSize(width: 260, height: 220)
        case .httpRequest:      return CGSize(width: 240, height: 200)
        case .jsonPath:         return CGSize(width: 220, height: 140)
        case .outputText:       return CGSize(width: 280, height: 220)
        case .outputImage:      return CGSize(width: 280, height: 220)
        case .macroNode:        return CGSize(width: 260, height: 280)
        case .macroInEdge:      return CGSize(width: 180, height: 100)
        case .macroInParam:     return CGSize(width: 180, height: 100)
        case .macroOutput:      return CGSize(width: 180, height: 100)
        case .macroConnections: return CGSize(width: 180, height: 80)
        }
    }

    var title: String {
        switch self {
        case .inputText:        return "INPUT TEXT"
        case .inputImage:       return "INPUT IMAGE"
        case .customScript:     return "CUSTOM SCRIPT"
        case .httpRequest:      return "HTTP REQUEST"
        case .jsonPath:         return "JSON PATH"
        case .outputText:       return "OUTPUT TEXT"
        case .outputImage:      return "OUTPUT IMAGE"
        case .macroNode:        return "MACRO NODE"
        case .macroInEdge:      return "MACRO IN"
        case .macroInParam:     return "MACRO IN"
        case .macroOutput:      return "MACRO OUT"
        case .macroConnections: return "MACRO CONNS"
        }
    }

    var subtitle: String {
        switch self {
        case .inputText:        return "string data"
        case .inputImage:       return "base64 data"
        case .customScript:     return "js execution"
        case .httpRequest:      return "fetch api"
        case .jsonPath:         return "extract data"
        case .outputText:       return "stream render"
        case .outputImage:      return "image render"
        case .macroNode:        return "sub-graph logic"
        case .macroInEdge:      return "edge"
        case .macroInParam:     return "param"
        case .macroOutput:      return "pass through"
        case .macroConnections: return "active ports"
        }
    }

    var isMacroInternal: Bool {
        switch self {
        case .macroInEdge, .macroInParam, .macroOutput, .macroConnections: return true
        default: return false
        }
    }

    var systemImage: String {
        switch self {
        case .inputText:        return "text.cursor"
        case .inputImage:       return "photo"
        case .customScript:     return "chevron.left.forwardslash.chevron.right"
        case .httpRequest:      return "network"
        case .jsonPath:         return "doc.text.magnifyingglass"
        case .outputText:       return "text.alignleft"
        case .outputImage:      return "photo.artframe"
        case .macroNode:        return "square.stack.3d.up"
        case .macroInEdge:      return "arrow.right.circle"
        case .macroInParam:     return "gearshape"
        case .macroOutput:      return "arrow.left.circle"
        case .macroConnections: return "link"
        }
    }
}

// MARK: - Node Data Model

nonisolated struct FlowNodeData: Equatable, Sendable, Hashable, Codable {
    var label: String = ""
    var value: String = ""
    var script: String = ""
    var path: String = ""
    var param: String = ""
    var inputs: [String]?
    var key: String?
    var model: String?
}

// MARK: - Handle Config

struct HandleConfig: Identifiable {
    let id: String
    let label: String
    let offsetY: CGFloat
}

func getHandles(for node: Node<FlowNodeData>, allNodes: [Node<FlowNodeData>]) -> (sources: [HandleConfig], targets: [HandleConfig]) {
    let nodeType = FlowNodeType(rawValue: node.type)
    var sources: [HandleConfig] = []
    var targets: [HandleConfig] = []

    switch nodeType {
    case .inputText, .inputImage:
        sources.append(HandleConfig(id: "out", label: "OUT", offsetY: 70))

    case .customScript:
        let ins = node.data.inputs ?? ["in1", "in2", "in3", "in4"]
        for (i, inputId) in ins.enumerated() {
            targets.append(HandleConfig(id: inputId, label: inputId.uppercased(), offsetY: 60 + CGFloat(i) * 35))
        }
        let outY = max(110, 60 + CGFloat(max(0, ins.count - 1)) * 35 / 2)
        sources.append(HandleConfig(id: "out", label: "OUT", offsetY: outY))

    case .httpRequest:
        for (i, hid) in ["method", "url", "headers", "body"].enumerated() {
            targets.append(HandleConfig(id: hid, label: hid.uppercased(), offsetY: 60 + CGFloat(i) * 35))
        }
        sources.append(HandleConfig(id: "out", label: "RESPONSE", offsetY: 100))

    case .jsonPath:
        targets.append(HandleConfig(id: "json", label: "JSON", offsetY: 70))
        sources.append(HandleConfig(id: "out", label: "RESULT", offsetY: 70))

    case .outputText, .outputImage:
        targets.append(HandleConfig(id: "in", label: "IN", offsetY: 110))

    case .macroInEdge, .macroInParam, .macroConnections:
        sources.append(HandleConfig(id: "out", label: "OUT", offsetY: 50))

    case .macroOutput:
        targets.append(HandleConfig(id: "in", label: "IN", offsetY: 50))

    case .macroNode:
        let mIns = allNodes.filter { $0.parentId == node.id && $0.type == "macroInEdge" }
        let mOuts = allNodes.filter { $0.parentId == node.id && $0.type == "macroOutput" }
        for (i, mIn) in mIns.enumerated() {
            let p = mIn.data.param.isEmpty ? "in\(i)" : mIn.data.param
            targets.append(HandleConfig(id: p, label: p.uppercased(), offsetY: 50 + CGFloat(i) * 30))
        }
        for (i, mOut) in mOuts.enumerated() {
            let p = mOut.data.param.isEmpty ? "out\(i)" : mOut.data.param
            sources.append(HandleConfig(id: p, label: p.uppercased(), offsetY: 50 + CGFloat(i) * 30))
        }

    case nil:
        break
    }

    return (sources, targets)
}

// MARK: - Typealiases

typealias FNode = Node<FlowNodeData>
typealias FEdge = FlowEdge<EmptyEdgeData>

// MARK: - Initial Graph

func makeInitialNodes() -> [FNode] {
    [
        FNode(id: "prompt", position: XYPosition(x: 80, y: 150),
              data: FlowNodeData(label: "Prompt", value: "Change the image, add a red balloon"),
              type: "inputText"),
        FNode(id: "image", position: XYPosition(x: 80, y: 350),
              data: FlowNodeData(label: "Image"),
              type: "inputImage"),
        FNode(id: "openRouter", position: XYPosition(x: 450, y: 200),
              data: FlowNodeData(label: "OpenRouter API", key: "", model: "black-forest-labs/flux.2-klein-4b"),
              type: "macroNode"),
        FNode(id: "outText", position: XYPosition(x: 850, y: 100),
              data: FlowNodeData(label: "Response Text"),
              type: "outputText"),
        FNode(id: "outImage", position: XYPosition(x: 850, y: 400),
              data: FlowNodeData(label: "Generated Image"),
              type: "outputImage"),

        // Macro internals
        FNode(id: "mInKey", position: XYPosition(x: 50, y: 80),
              data: FlowNodeData(param: "key"), type: "macroInParam", parentId: "openRouter"),
        FNode(id: "mInModel", position: XYPosition(x: 50, y: 220),
              data: FlowNodeData(param: "model"), type: "macroInParam", parentId: "openRouter"),
        FNode(id: "mInPrompt", position: XYPosition(x: 50, y: 360),
              data: FlowNodeData(param: "prompt"), type: "macroInEdge", parentId: "openRouter"),
        FNode(id: "mInImage", position: XYPosition(x: 50, y: 500),
              data: FlowNodeData(param: "image"), type: "macroInEdge", parentId: "openRouter"),
        FNode(id: "mConns", position: XYPosition(x: 50, y: 640),
              data: FlowNodeData(), type: "macroConnections", parentId: "openRouter"),
        FNode(id: "mMethod", position: XYPosition(x: 400, y: 80),
              data: FlowNodeData(label: "Method", value: "POST"), type: "inputText", parentId: "openRouter"),
        FNode(id: "mUrl", position: XYPosition(x: 400, y: 240),
              data: FlowNodeData(label: "URL", value: "https://openrouter.ai/api/v1/chat/completions"),
              type: "inputText", parentId: "openRouter"),
        FNode(id: "scriptAuth", position: XYPosition(x: 400, y: 400),
              data: FlowNodeData(
                  script: "return JSON.stringify({\n  \"Authorization\": \"Bearer \" + in1,\n  \"Content-Type\": \"application/json\"\n});",
                  inputs: ["in1"]),
              type: "customScript", parentId: "openRouter"),
        FNode(id: "scriptBody", position: XYPosition(x: 400, y: 650),
              data: FlowNodeData(
                  script: "var content;\nif (in2 && in2.length > 0) {\n  content = [\n    { type: \"text\", text: in3 || \"\" },\n    { type: \"image_url\", image_url: { url: in2 } }\n  ];\n} else {\n  content = in3 || \"\";\n}\nvar payload = {\n  model: in1,\n  stream: true,\n  messages: [{ role: \"user\", content: content }]\n};\nreturn JSON.stringify(payload);",
                  inputs: ["in1", "in2", "in3", "in4"]),
              type: "customScript", parentId: "openRouter"),
        FNode(id: "httpReq", position: XYPosition(x: 750, y: 300),
              data: FlowNodeData(), type: "httpRequest", parentId: "openRouter"),
        FNode(id: "pathText", position: XYPosition(x: 1050, y: 180),
              data: FlowNodeData(path: "choices.0.delta.content"), type: "jsonPath", parentId: "openRouter"),
        FNode(id: "pathImage", position: XYPosition(x: 1050, y: 450),
              data: FlowNodeData(path: "choices.0.delta.images.0.image_url.url"), type: "jsonPath", parentId: "openRouter"),
        FNode(id: "mOutText", position: XYPosition(x: 1350, y: 180),
              data: FlowNodeData(param: "text"), type: "macroOutput", parentId: "openRouter"),
        FNode(id: "mOutImage", position: XYPosition(x: 1350, y: 450),
              data: FlowNodeData(param: "image"), type: "macroOutput", parentId: "openRouter"),
    ]
}

func makeInitialEdges() -> [FEdge] {
    [
        FEdge(id: "e3", source: "prompt", target: "openRouter", sourceHandle: "out", targetHandle: "prompt"),
        FEdge(id: "e4", source: "image", target: "openRouter", sourceHandle: "out", targetHandle: "image"),
        FEdge(id: "e5", source: "openRouter", target: "outText", sourceHandle: "text", targetHandle: "in"),
        FEdge(id: "e6", source: "openRouter", target: "outImage", sourceHandle: "image", targetHandle: "in"),
        FEdge(id: "m1", source: "mInKey", target: "scriptAuth", sourceHandle: "out", targetHandle: "in1"),
        FEdge(id: "m2", source: "mInModel", target: "scriptBody", sourceHandle: "out", targetHandle: "in1"),
        FEdge(id: "m3", source: "mInImage", target: "scriptBody", sourceHandle: "out", targetHandle: "in2"),
        FEdge(id: "m4", source: "mInPrompt", target: "scriptBody", sourceHandle: "out", targetHandle: "in3"),
        FEdge(id: "m13", source: "mConns", target: "scriptBody", sourceHandle: "out", targetHandle: "in4"),
        FEdge(id: "m5", source: "mMethod", target: "httpReq", sourceHandle: "out", targetHandle: "method"),
        FEdge(id: "m6", source: "mUrl", target: "httpReq", sourceHandle: "out", targetHandle: "url"),
        FEdge(id: "m7", source: "scriptAuth", target: "httpReq", sourceHandle: "out", targetHandle: "headers"),
        FEdge(id: "m8", source: "scriptBody", target: "httpReq", sourceHandle: "out", targetHandle: "body"),
        FEdge(id: "m9", source: "httpReq", target: "pathText", sourceHandle: "out", targetHandle: "json"),
        FEdge(id: "m10", source: "httpReq", target: "pathImage", sourceHandle: "out", targetHandle: "json"),
        FEdge(id: "m11", source: "pathText", target: "mOutText", sourceHandle: "out", targetHandle: "in"),
        FEdge(id: "m12", source: "pathImage", target: "mOutImage", sourceHandle: "out", targetHandle: "in"),
    ]
}

// MARK: - Runtime State (Observable)

@Observable
@MainActor
final class FlowRuntime {
    var runStatus: String = "IDLE"
    var displayData: [String: String] = [:]
    var computingNodes: Set<String> = []
    var activeEdgeIds: Set<String> = []
    var edgeActivationTime: [String: Date] = [:]
    var nodeErrors: [String: String] = [:]
    var frozenNodes: Set<String> = []

    // Engine state
    private var expectedInputs: [String: Set<String>] = [:]
    private var receivedInputs: [String: [String: Any]] = [:]
    private var flowNodes: [FNode] = []
    private var flowEdges: [FEdge] = []
    private var currentTask: Task<Void, Never>?

    func reset() {
        currentTask?.cancel()
        currentTask = nil
        runStatus = "IDLE"
        displayData = [:]
        computingNodes = []
        activeEdgeIds = []
        edgeActivationTime = [:]
        nodeErrors = [:]
        frozenNodes = []
        expectedInputs = [:]
        receivedInputs = [:]
    }

    func runFlow(nodes: [FNode], edges: [FEdge]) {
        reset()
        runStatus = "RUNNING..."
        flowNodes = nodes
        flowEdges = edges

        // Build expected inputs
        for e in edges {
            var tId = e.target
            var tHandle = e.targetHandle ?? "in"
            if let tNode = nodes.first(where: { $0.id == tId }), tNode.type == "macroNode",
               let mIn = nodes.first(where: { $0.parentId == tId && $0.type == "macroInEdge" && $0.data.param == tHandle }) {
                tId = mIn.id
                tHandle = "in"
            }
            expectedInputs[tId, default: Set()].insert(tHandle)
        }

        // Execute root nodes
        currentTask = Task { @MainActor in
            for n in nodes where expectedInputs[n.id] == nil || expectedInputs[n.id]!.isEmpty {
                guard !Task.isCancelled else { return }
                await executeNode(n.id, isStream: false)
            }
        }
    }

    private func executeNode(_ nodeId: String, isStream: Bool) async {
        computingNodes.insert(nodeId)

        guard let node = flowNodes.first(where: { $0.id == nodeId }) else {
            computingNodes.remove(nodeId)
            return
        }

        let nodeType = FlowNodeType(rawValue: node.type)
        let inputs = receivedInputs[nodeId] ?? [:]

        // Compute this node's output value (sync work)
        var outputHandle: String?
        var outputValue: Any?

        switch nodeType {
        case .inputText, .inputImage:
            outputHandle = "out"
            outputValue = node.data.value

        case .macroConnections:
            let parentId = node.parentId
            let externalEdges = flowEdges.filter { $0.source == parentId }
            let activePorts = Array(Set(externalEdges.compactMap { $0.sourceHandle }))
            if let data = try? JSONSerialization.data(withJSONObject: activePorts),
               let str = String(data: data, encoding: .utf8) {
                outputHandle = "out"
                outputValue = str
            }

        case .macroInParam:
            if let parent = flowNodes.first(where: { $0.id == node.parentId }) {
                let paramVal: String
                switch node.data.param {
                case "key": paramVal = parent.data.key ?? ""
                case "model": paramVal = parent.data.model ?? ""
                default: paramVal = ""
                }
                outputHandle = "out"
                outputValue = paramVal
            }

        case .macroInEdge:
            if let val = inputs["in"] {
                outputHandle = "out"
                outputValue = val
            }

        case .macroOutput:
            if let val = inputs["in"] {
                outputHandle = "in"
                outputValue = val
            }

        case .customScript:
            let result = evaluateScript(node.data.script, inputs: inputs)
            outputHandle = "out"
            outputValue = result

        case .httpRequest:
            // HTTP is async — stays computing during the request
            let urlStr = (inputs["url"] as? String) ?? ""
            if !urlStr.isEmpty {
                await performHTTP(node: node, inputs: inputs)
            }
            computingNodes.remove(nodeId)
            return

        case .jsonPath:
            if let jsonObj = inputs["json"] {
                if let val = resolveJSONPath(jsonObj, path: node.data.path), val is NSNull == false {
                    if isStream, let strVal = val as? String {
                        displayData[nodeId] = (displayData[nodeId] ?? "") + strVal
                    }
                    outputHandle = "out"
                    outputValue = val
                }
            }

        case .outputText:
            if let val = inputs["in"] {
                let str = "\(val)"
                displayData[nodeId] = isStream ? (displayData[nodeId] ?? "") + str : str
            }

        case .outputImage:
            if let val = inputs["in"] as? String {
                displayData[nodeId] = val
            }

        default:
            break
        }

        // Node's own work is done — remove from computing
        computingNodes.remove(nodeId)

        // Now propagate to downstream nodes (this is async but the current node is no longer "computing")
        if let handle = outputHandle, let value = outputValue {
            await pushValue(node.id, handle, value, isStream: isStream)
        }
    }

    // MARK: - JavaScript Evaluation

    private func evaluateScript(_ script: String, inputs: [String: Any]) -> String {
        guard let ctx = JSContext() else { return "" }

        for (key, val) in inputs {
            if let strVal = val as? String {
                ctx.setObject(strVal, forKeyedSubscript: key as NSString)
            } else if let arrVal = val as? [Any],
                      let data = try? JSONSerialization.data(withJSONObject: arrVal),
                      let jsonStr = String(data: data, encoding: .utf8) {
                ctx.evaluateScript("var \(key) = \(jsonStr);")
            } else {
                ctx.setObject("\(val)", forKeyedSubscript: key as NSString)
            }
        }

        let wrapped = script.contains("return ")
            ? "(function() { \(script) })()"
            : script

        if let result = ctx.evaluateScript(wrapped) {
            if result.isUndefined || result.isNull {
                return ""
            }
            return result.toString() ?? ""
        }
        return ""
    }

    // MARK: - Push Value

    private func pushValue(_ sourceId: String, _ sourceHandle: String, _ value: Any, isStream: Bool) async {
        var sId = sourceId
        var sHandle = sourceHandle

        if let sourceNode = flowNodes.first(where: { $0.id == sId }), sourceNode.type == "macroOutput" {
            sId = sourceNode.parentId ?? sId
            sHandle = sourceNode.data.param
        }

        let outEdges = flowEdges.filter { $0.source == sId && $0.sourceHandle == sHandle }
        for e in outEdges {
            activeEdgeIds.insert(e.id)
            edgeActivationTime[e.id] = Date()
            let edgeId = e.id
            Task { @MainActor [weak self] in
                try? await Task.sleep(for: .milliseconds(900))
                self?.activeEdgeIds.remove(edgeId)
                self?.edgeActivationTime.removeValue(forKey: edgeId)
            }

            var tId = e.target
            var tHandle = e.targetHandle ?? "in"

            if let targetNode = flowNodes.first(where: { $0.id == tId }), targetNode.type == "macroNode",
               let mIn = flowNodes.first(where: { $0.parentId == tId && $0.type == "macroInEdge" && $0.data.param == tHandle }) {
                tId = mIn.id
                tHandle = "in"
            }

            receivedInputs[tId, default: [:]][tHandle] = value

            if let expected = expectedInputs[tId],
               (receivedInputs[tId]?.count ?? 0) >= expected.count {
                // Small delay so edge animation is visible before next node starts
                try? await Task.sleep(for: .milliseconds(200))
                await executeNode(tId, isStream: isStream)
            }
        }
    }

    // MARK: - HTTP Request (with streaming support)

    private func performHTTP(node: FNode, inputs: [String: Any]) async {
        guard let urlStr = inputs["url"] as? String, let url = URL(string: urlStr) else { return }
        let method = (inputs["method"] as? String) ?? "GET"
        var request = URLRequest(url: url)
        request.httpMethod = method

        if let headersStr = inputs["headers"] as? String,
           let headersData = headersStr.data(using: .utf8),
           let headers = try? JSONSerialization.jsonObject(with: headersData) as? [String: String] {
            for (k, v) in headers { request.setValue(v, forHTTPHeaderField: k) }
        }

        var bodyStr: String?
        if method != "GET", let body = inputs["body"] as? String {
            request.httpBody = body.data(using: .utf8)
            bodyStr = body
        }

        // Detect if streaming was requested in the body
        let isStreamRequest: Bool = {
            guard let bs = bodyStr,
                  let data = bs.data(using: .utf8),
                  let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return false }
            return (obj["stream"] as? Bool) == true
        }()

        do {
            if isStreamRequest {
                await performStreamingHTTP(node: node, request: request)
            } else {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let httpResp = response as? HTTPURLResponse else { return }
                if httpResp.statusCode < 200 || httpResp.statusCode >= 300 {
                    let text = String(data: data, encoding: .utf8) ?? "Unknown error"
                    nodeErrors[node.id] = "\(httpResp.statusCode): \(text)"
                    runStatus = "ERROR"
                    return
                }
                if let json = try? JSONSerialization.jsonObject(with: data) {
                    await pushValue(node.id, "out", json, isStream: false)
                }
                runStatus = "COMPLETED"
            }
        } catch {
            nodeErrors[node.id] = error.localizedDescription
            runStatus = "ERROR"
        }
    }

    private func performStreamingHTTP(node: FNode, request: URLRequest) async {
        do {
            let (bytes, response) = try await URLSession.shared.bytes(for: request)
            guard let httpResp = response as? HTTPURLResponse else { return }
            if httpResp.statusCode < 200 || httpResp.statusCode >= 300 {
                var errorData = Data()
                for try await byte in bytes { errorData.append(byte) }
                let text = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                nodeErrors[node.id] = "\(httpResp.statusCode): \(text)"
                runStatus = "ERROR"
                return
            }

            for try await line in bytes.lines {
                guard !Task.isCancelled else { break }

                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard trimmed.hasPrefix("data: ") else { continue }
                let payload = String(trimmed.dropFirst(6))
                if payload == "[DONE]" { break }

                guard let chunkData = payload.data(using: .utf8),
                      let json = try? JSONSerialization.jsonObject(with: chunkData) else { continue }

                await pushValue(node.id, "out", json, isStream: true)
            }
            runStatus = "COMPLETED"
        } catch {
            if !Task.isCancelled {
                nodeErrors[node.id] = error.localizedDescription
                runStatus = "ERROR"
            }
        }
    }

    // MARK: - JSON Path

    private func resolveJSONPath(_ obj: Any, path: String) -> Any? {
        let components = path.split(separator: ".").map(String.init)
        var current: Any = obj
        for comp in components {
            if let dict = current as? [String: Any], let next = dict[comp] {
                current = next
            } else if let arr = current as? [Any], let idx = Int(comp), idx < arr.count {
                current = arr[idx]
            } else {
                return nil
            }
        }
        return current
    }
}

// MARK: - Node Content View

// MARK: - Handle Label View

struct HandleLabel: View {
    let label: String
    let isLeft: Bool

    var body: some View {
        Text(label)
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .tracking(1)
            .foregroundColor(.cyanAccent)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.canvasBg)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.borderMid, lineWidth: 1))
            .shadow(color: .black.opacity(0.8), radius: 4)
            .offset(x: isLeft ? -4 : 4)
            .allowsHitTesting(false)
    }
}

struct FlowNodeContent: View {
    let node: FNode
    let allNodes: [FNode]
    let runtime: FlowRuntime
    let onUpdateValue: (String, String) -> Void
    let onUpdateScript: (String, String) -> Void
    let onUpdatePath: (String, String) -> Void
    let onUpdateParam: (String, String) -> Void
    let onUpdateLabel: (String, String) -> Void
    let onUpdateKey: (String, String) -> Void
    let onUpdateModel: (String, String) -> Void
    let onUpdateInputs: (String, [String]) -> Void
    let onPreviewImage: (String) -> Void
    let onDelete: (String) -> Void
    let onRename: (String) -> Void

    var nodeType: FlowNodeType { FlowNodeType(rawValue: node.type) ?? .inputText }
    var dims: CGSize { nodeType.dimensions }
    var isMacro: Bool { nodeType == .macroNode }

    var isComputing: Bool {
        runtime.computingNodes.contains(node.id) ||
        (node.type == "macroNode" && allNodes.contains(where: {
            $0.parentId == node.id && runtime.computingNodes.contains($0.id)
        }))
    }

    var isFrozen: Bool { runtime.frozenNodes.contains(node.id) }
    var isError: Bool { runtime.nodeErrors[node.id] != nil }
    @State private var isHovered = false
    @State private var pulseOpacity: CGFloat = 1.0
    private var showTools: Bool { isHovered }

    var body: some View {
        let handles = getHandles(for: node, allNodes: allNodes)

        ZStack {
            // Computing pulse overlay
            if isComputing {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.greenAccent.opacity(0.08 * pulseOpacity))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.greenAccent.opacity(0.6 * pulseOpacity), lineWidth: 2)
                    )
                    .shadow(color: Color.greenAccent.opacity(0.5 * pulseOpacity), radius: 20)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                            pulseOpacity = 0.3
                        }
                    }
                    .onDisappear {
                        pulseOpacity = 1.0
                    }
            }

            // Node background
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.nodeBg.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(borderColor, lineWidth: isComputing ? 2 : 1)
                )
                .shadow(color: shadowColor, radius: isComputing ? 15 : 8)

            VStack(spacing: 0) {
                headerBar
                nodeContent
                    .padding(12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Error banner
            if isError, let msg = runtime.nodeErrors[node.id] {
                VStack {
                    Spacer()
                    Text("ERROR: \(msg)")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity)
                        .padding(4)
                        .background(Color.red)
                        .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 12, bottomTrailingRadius: 12))
                }
            }

            // Floating toolbar (top, inside bounds)
            if showTools {
                VStack {
                    HStack {
                        Button(action: { onRename(node.id) }) {
                            Text("\u{270E}")
                                .font(.system(size: 10))
                                .frame(width: 22, height: 22)
                                .background(Color.borderMid)
                                .foregroundColor(.textMuted)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.borderDim, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        .flowCursor(.pointer)

                        Spacer()

                        Button(action: { onDelete(node.id) }) {
                            Text("\u{2715}")
                                .font(.system(size: 10))
                                .frame(width: 22, height: 22)
                                .background(Color.borderMid)
                                .foregroundColor(.textMuted)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.borderDim, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        .flowCursor(.pointer)
                    }
                    .padding(.horizontal, 4)
                    .padding(.top, 4)
                    Spacer()
                }
                .transition(.opacity.animation(.easeInOut(duration: 0.15)))
            }
        }
        .frame(width: dims.width, height: dynamicHeight)
        .contentShape(Rectangle())
        .animation(.easeInOut(duration: 0.5), value: isComputing)
        .animation(.easeInOut(duration: 0.3), value: isError)
        .animation(.easeInOut(duration: 0.3), value: isFrozen)
        #if canImport(AppKit)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        #endif
        // Source handles + labels (right)
        .overlay(alignment: .topTrailing) {
            ForEach(handles.sources) { h in
                Handle(nodeId: node.id, id: h.id, type: .source, position: .right, color: .cyanAccent)
                    .overlay(alignment: .trailing) {
                        HandleLabel(label: h.label, isLeft: false)
                            .fixedSize()
                            .offset(x: 4)
                            .frame(width: 0, alignment: .leading)
                    }
                    .offset(x: 6, y: h.offsetY - 6)
            }
        }
        // Target handles + labels (left)
        .overlay(alignment: .topLeading) {
            ForEach(handles.targets) { h in
                Handle(nodeId: node.id, id: h.id, type: .target, position: .left, color: .cyanAccent)
                    .overlay(alignment: .leading) {
                        HandleLabel(label: h.label, isLeft: true)
                            .fixedSize()
                            .offset(x: -4)
                            .frame(width: 0, alignment: .trailing)
                    }
                    .offset(x: -6, y: h.offsetY - 6)
            }
        }
    }

    private var dynamicHeight: CGFloat {
        if nodeType == .customScript {
            let inputCount = CGFloat((node.data.inputs ?? ["in1", "in2", "in3", "in4"]).count)
            return max(dims.height, 60 + inputCount * 35 + 30)
        }
        return dims.height
    }

    private var borderColor: Color {
        if isError { return .red }
        if isFrozen { return .orange }
        if isComputing { return .greenAccent }
        if isMacro { return .cyanAccent.opacity(0.3) }
        return .borderDim
    }

    private var shadowColor: Color {
        if isError { return .red.opacity(0.4) }
        if isFrozen { return .orange.opacity(0.4) }
        if isComputing { return .greenAccent.opacity(0.4) }
        if isMacro { return .cyanAccent.opacity(0.1) }
        return .black.opacity(0.3)
    }

    private var headerBar: some View {
        HStack(spacing: 6) {
            if isComputing {
                Circle()
                    .fill(Color.greenAccent)
                    .frame(width: 6, height: 6)
                    .shadow(color: .greenAccent, radius: 4)
            } else if isFrozen {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 6, height: 6)
            } else if isError {
                Circle()
                    .fill(Color.red)
                    .frame(width: 6, height: 6)
            }
            Text(node.data.label.isEmpty ? nodeType.title : node.data.label)
                .font(.system(size: 10, weight: .bold))
                .tracking(1.5)
                .foregroundColor(isComputing ? .greenAccent : isFrozen ? .orange : (isMacro ? .cyanAccent : .white))
                .textCase(.uppercase)
                .lineLimit(1)
            Spacer()
            if isComputing {
                Text("RUNNING")
                    .font(.system(size: 7, weight: .bold, design: .monospaced))
                    .foregroundColor(.greenAccent)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.greenAccent.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            } else if isFrozen {
                Text("FROZEN")
                    .font(.system(size: 7, weight: .bold, design: .monospaced))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            } else {
                Text(nodeType.subtitle)
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundColor(.textMuted)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 32)
        .background(Color.canvasBg.opacity(0.5))
    }

    @ViewBuilder
    private var nodeContent: some View {
        switch nodeType {
        case .inputText:
            TextEditor(text: Binding(
                get: { node.data.value },
                set: { onUpdateValue(node.id, $0) }
            ))
            .font(.system(size: 11, design: .monospaced))
            .foregroundColor(.white)
            .scrollContentBackground(.hidden)
            .background(Color.fieldBg)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.borderMid))

        case .inputImage:
            inputImageBody

        case .customScript:
            customScriptBody

        case .httpRequest:
            Text("FETCH ENGINE")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.white.opacity(0.5))
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .jsonPath:
            VStack(alignment: .leading, spacing: 4) {
                Text("SELECTOR PATH")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.textMuted)
                TextField("", text: Binding(
                    get: { node.data.path },
                    set: { onUpdatePath(node.id, $0) }
                ))
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.white)
                .textFieldStyle(.plain)
                .padding(8)
                .background(Color.fieldBg)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.borderMid))
            }

        case .outputText:
            VStack(spacing: 0) {
                ScrollView {
                    Text(runtime.displayData[node.id] ?? "Waiting for data...")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(runtime.displayData[node.id] != nil ? .white : .white.opacity(0.3))
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .textSelection(.enabled)
                }
                if runtime.displayData[node.id] != nil {
                    HStack {
                        Spacer()
                        Button(action: {
                            #if canImport(AppKit)
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(runtime.displayData[node.id] ?? "", forType: .string)
                            #endif
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 8))
                                Text("COPY")
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                            }
                            .foregroundColor(.cyanAccent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.canvasBg.opacity(0.8))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.borderMid))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 4)
                }
            }
            .padding(8)
            .background(Color.fieldBg)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.borderMid))

        case .outputImage:
            Group {
                if let imgUrl = runtime.displayData[node.id], !imgUrl.isEmpty {
                    ZStack(alignment: .topTrailing) {
                        AsyncImage(url: URL(string: imgUrl)) { img in
                            img.resizable().aspectRatio(contentMode: .fit)
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                        Button(action: { onPreviewImage(imgUrl) }) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .font(.system(size: 8))
                                Text("VIEW")
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                            }
                            .foregroundColor(.cyanAccent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.canvasBg.opacity(0.9))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.borderMid))
                        }
                        .buttonStyle(.plain)
                        .padding(4)
                    }
                } else {
                    Text("No Image")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.white.opacity(0.3))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .background(Color.fieldBg)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.borderMid))

        case .macroNode:
            macroNodeBody

        case .macroInParam, .macroInEdge, .macroOutput:
            VStack(alignment: .leading, spacing: 4) {
                Text("PORT NAME")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.textMuted)
                TextField("", text: Binding(
                    get: { node.data.param },
                    set: { onUpdateParam(node.id, $0) }
                ))
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.white)
                .textFieldStyle(.plain)
                .padding(8)
                .background(Color.fieldBg)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.borderMid))
            }

        case .macroConnections:
            Text("TRACKS EXTERNAL\nCONNECTIONS")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var inputImageBody: some View {
        Group {
            if node.data.value.isEmpty {
                Button(action: { pickImage() }) {
                    VStack(spacing: 4) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 20))
                            .foregroundColor(.textMuted)
                        Text("CLICK TO UPLOAD")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.textMuted)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.fieldBg)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [5, 3]))
                            .foregroundColor(.borderMid)
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            } else {
                ZStack(alignment: .topTrailing) {
                    if let nsImage = base64ToNSImage(node.data.value) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        Text("Image loaded")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.white.opacity(0.5))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    VStack(spacing: 4) {
                        Button(action: { onPreviewImage("base64:" + node.data.value) }) {
                            Text("VIEW")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(.cyanAccent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.canvasBg.opacity(0.9))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.borderDim))
                        }
                        .buttonStyle(.plain)
                        Button(action: { onUpdateValue(node.id, "") }) {
                            Text("CLEAR")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.canvasBg.opacity(0.9))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.borderDim))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(4)
                }
                .background(Color.fieldBg)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.borderMid))
            }
        }
    }

    private func pickImage() {
        #if canImport(AppKit)
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url,
           let data = try? Data(contentsOf: url) {
            let base64 = "data:image/png;base64," + data.base64EncodedString()
            onUpdateValue(node.id, base64)
        }
        #endif
    }

    private func base64ToNSImage(_ str: String) -> NSImage? {
        #if canImport(AppKit)
        guard let commaIndex = str.firstIndex(of: ",") else { return nil }
        let base64Part = String(str[str.index(after: commaIndex)...])
        guard let data = Data(base64Encoded: base64Part) else { return nil }
        return NSImage(data: data)
        #else
        return nil
        #endif
    }

    private var customScriptBody: some View {
        let inputsList = node.data.inputs ?? ["in1", "in2", "in3", "in4"]
        return VStack(spacing: 4) {
            HStack {
                Text("PORTS (\(inputsList.count))")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.textMuted)
                    .tracking(1)
                Spacer()
                HStack(spacing: 4) {
                    Button(action: {
                        onUpdateInputs(node.id, inputsList + ["in\(inputsList.count + 1)"])
                    }) {
                        Text("+").font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.cyanAccent)
                            .frame(width: 20, height: 20)
                            .background(Color.borderMid)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }.buttonStyle(.plain)

                    Button(action: {
                        if !inputsList.isEmpty { onUpdateInputs(node.id, Array(inputsList.dropLast())) }
                    }) {
                        Text("-").font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.red)
                            .frame(width: 20, height: 20)
                            .background(Color.borderMid)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }.buttonStyle(.plain)
                }
            }

            TextEditor(text: Binding(
                get: { node.data.script },
                set: { onUpdateScript(node.id, $0) }
            ))
            .font(.system(size: 11, design: .monospaced))
            .foregroundColor(.white)
            .scrollContentBackground(.hidden)
            .background(Color.fieldBg)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.borderMid))
        }
    }

    private var macroNodeBody: some View {
        let paramNodes = allNodes.filter { $0.parentId == node.id && $0.type == "macroInParam" }
        return VStack(spacing: 12) {
            if paramNodes.isEmpty {
                VStack(spacing: 4) {
                    Text("DOUBLE CLICK").font(.system(size: 12, design: .monospaced)).foregroundColor(.white.opacity(0.6))
                    Text("TO ENTER").font(.system(size: 10, design: .monospaced)).foregroundColor(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ForEach(paramNodes) { pNode in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(pNode.data.param.uppercased())
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.textMuted)
                            .tracking(1)

                        if pNode.data.param.lowercased().contains("key") {
                            SecureField("", text: Binding(
                                get: { node.data.key ?? "" },
                                set: { onUpdateKey(node.id, $0) }
                            ))
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.white)
                            .textFieldStyle(.plain)
                            .padding(8)
                            .background(Color.fieldBg)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.borderMid))
                            .onTapGesture(count: 2) { }
                        } else {
                            TextField("", text: Binding(
                                get: {
                                    pNode.data.param == "model" ? (node.data.model ?? "") : ""
                                },
                                set: { onUpdateModel(node.id, $0) }
                            ))
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.white)
                            .textFieldStyle(.plain)
                            .padding(8)
                            .background(Color.fieldBg)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.borderMid))
                            .onTapGesture(count: 2) { }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Edge Flow Animation

/// Animates a glowing segment traveling along an edge path from source to target.
struct EdgeFlowAnimation: View {
    let path: Path
    let activationTime: Date
    let duration: Double

    var body: some View {
        TimelineView(.animation) { timeline in
            let elapsed = timeline.date.timeIntervalSince(activationTime)
            let progress = min(elapsed / duration, 1.0)
            let headLength: Double = 0.25

            let trimFrom = max(0, progress - headLength)
            let trimTo = progress

            // Traveling glow segment
            path.trimmedPath(from: trimFrom, to: trimTo)
                .stroke(
                    Color.greenAccent,
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .shadow(color: Color.greenAccent.opacity(0.8), radius: 6)
                .shadow(color: Color.greenAccent.opacity(0.4), radius: 12)
                .opacity(progress >= 1.0 ? max(0, 1.0 - (elapsed - duration) / 0.2) : 1.0)
        }
    }
}

// MARK: - Main Content View

struct ContentView: View {
    @State private var nodes: [FNode] = makeInitialNodes()
    @State private var edges: [FEdge] = makeInitialEdges()
    @StateObject private var instance = SwiftFlowInstance()
    @State private var runtime = FlowRuntime()

    // Macro navigation
    @State private var currentView: String? = nil

    // UI state
    @State private var editingNodeId: String? = nil
    @State private var editNodeLabel: String = ""
    @State private var previewImageURL: String? = nil
    @State private var previewBase64Image: String? = nil
    @State private var contextMenuPosition: CGPoint = .zero
    @State private var windowDragStart: CGPoint? = nil
    private var nodeCounter: Int { nodes.count }

    private var visibleNodes: [FNode] {
        nodes.filter { $0.parentId == currentView }
    }

    private var visibleEdges: [FEdge] {
        edges.filter { e in
            guard let s = nodes.first(where: { $0.id == e.source }),
                  let t = nodes.first(where: { $0.id == e.target }) else { return false }
            return s.parentId == currentView && t.parentId == currentView
        }.map { edge in
            var e = edge
            if runtime.activeEdgeIds.contains(e.id) {
                e.animated = true
                e.style = EdgeStyle(strokeColor: .greenAccent, strokeWidth: 3)
            }
            return e
        }
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                topBar
                canvas
            }
            .background(Color.canvasBg)

            // Rename modal
            if editingNodeId != nil {
                renameModal
            }

            // Image preview overlay
            if previewImageURL != nil || previewBase64Image != nil {
                imagePreviewOverlay
            }
        }
        #if os(macOS)
        .frame(minWidth: 900, minHeight: 600)
        #endif
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            HStack(spacing: 16) {
                Text("AI_FLOW")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .tracking(1)

                HStack(spacing: 8) {
                    Button("ROOT") { currentView = nil }
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(currentView == nil ? .cyanAccent : .textMuted)
                        .buttonStyle(.plain)
                        .flowCursor(.pointer)

                    if let cv = currentView, let mn = nodes.first(where: { $0.id == cv }) {
                        Text("/").font(.system(size: 10, design: .monospaced)).foregroundColor(.textMuted)
                        Text(mn.data.label.uppercased())
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.cyanAccent)
                    }
                }
            }

            Spacer()

            HStack(spacing: 16) {
                Text("Status: \(runtime.runStatus)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.textMuted)

                Text("Scroll to Zoom")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.textMuted)

                Text("Right-Click to Add")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.textMuted)
            }

            Spacer()

            Button(action: { runtime.runFlow(nodes: nodes, edges: edges) }) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.cyanAccent)
                        .frame(width: 8, height: 8)
                        .opacity(runtime.runStatus.contains("RUNNING") ? 0.5 : 1)
                    Text("EXECUTE")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .tracking(1)
                }
                .foregroundColor(.cyanAccent)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.cyanAccent))
            }
            .buttonStyle(.plain)
            .flowCursor(.pointer)
        }
        .padding(.leading, 80)
        .padding(.trailing, 24)
        .padding(.vertical, 12)
        .background(Color(red: 0.063, green: 0.078, blue: 0.098))
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.borderMid).frame(height: 1)
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 1)
                .onChanged { value in
                    #if canImport(AppKit)
                    guard let window = NSApp.keyWindow else { return }
                    if windowDragStart == nil {
                        windowDragStart = CGPoint(x: window.frame.origin.x, y: window.frame.origin.y)
                    }
                    if let start = windowDragStart {
                        window.setFrameOrigin(NSPoint(
                            x: start.x + value.translation.width,
                            y: start.y - value.translation.height
                        ))
                    }
                    #endif
                }
                .onEnded { _ in
                    windowDragStart = nil
                }
        )
    }

    // MARK: - Canvas

    private var canvas: some View {
        let theme: SwiftFlowTheme = {
            var t = SwiftFlowTheme.dark
            t.canvasBackgroundColor = .canvasBg
            t.edgeColor = .borderDim
            t.edgeWidth = 2
            t.handleColor = .cyanAccent
            t.handleSize = 12
            t.nodeBackgroundColor = .clear
            t.nodeSelectedBorderColor = .cyanAccent
            return t
        }()

        return SwiftFlow(
            nodes: visibleNodes,
            edges: visibleEdges,
            onNodesChange: { changes in
                var all = nodes
                for change in changes {
                    switch change {
                    case .position(let id, let pos):
                        if let i = all.firstIndex(where: { $0.id == id }) { all[i].position = pos }
                    case .selection(let id, let sel):
                        if let i = all.firstIndex(where: { $0.id == id }) { all[i].selected = sel }
                    case .remove(let id):
                        let children = all.filter { $0.parentId == id }.map(\.id)
                        all.removeAll { $0.id == id || children.contains($0.id) }
                        edges.removeAll { $0.source == id || $0.target == id || children.contains($0.source) || children.contains($0.target) }
                    case .add(let item):
                        all.append(item)
                    case .dimensions(let id, let w, let h):
                        if let i = all.firstIndex(where: { $0.id == id }) { all[i].width = w; all[i].height = h }
                    case .replace(let id, let item):
                        if let i = all.firstIndex(where: { $0.id == id }) { all[i] = item }
                    }
                }
                nodes = all
            },
            onEdgesChange: { edges = applyEdgeChanges($0, edges: edges) },
            onConnect: { edges = addEdge($0, edges: edges) },
            connectionLineType: .bezier,
            theme: theme,
            onNodeDoubleClick: { node in
                if node.type == "macroNode" { currentView = node.id }
            },
            swiftFlowInstance: instance,
            onNodeContextMenu: { node in
                editNodeLabel = node.data.label.isEmpty ? (FlowNodeType(rawValue: node.type)?.title ?? "") : node.data.label
                editingNodeId = node.id
            },
            edgeContent: { edge, pathResult in
                let isActive = runtime.activeEdgeIds.contains(edge.id)
                let color = edge.style?.strokeColor ?? (isActive ? Color.greenAccent : Color.borderDim)
                let width = edge.style?.strokeWidth ?? (isActive ? 3.0 : 2.0)
                return AnyView(
                    ZStack {
                        // Base edge line
                        pathResult.path.stroke(
                            color,
                            style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round)
                        )

                        // Traveling highlight animation
                        if isActive {
                            EdgeFlowAnimation(
                                path: pathResult.path,
                                activationTime: runtime.edgeActivationTime[edge.id] ?? Date(),
                                duration: 0.7
                            )
                        }
                    }
                )
            }
        ) { node in
            FlowNodeContent(
                node: node, allNodes: nodes, runtime: runtime,
                onUpdateValue: { id, val in if let i = nodes.firstIndex(where: { $0.id == id }) { nodes[i].data.value = val } },
                onUpdateScript: { id, val in if let i = nodes.firstIndex(where: { $0.id == id }) { nodes[i].data.script = val } },
                onUpdatePath: { id, val in if let i = nodes.firstIndex(where: { $0.id == id }) { nodes[i].data.path = val } },
                onUpdateParam: { id, val in if let i = nodes.firstIndex(where: { $0.id == id }) { nodes[i].data.param = val } },
                onUpdateLabel: { id, val in if let i = nodes.firstIndex(where: { $0.id == id }) { nodes[i].data.label = val } },
                onUpdateKey: { id, val in if let i = nodes.firstIndex(where: { $0.id == id }) { nodes[i].data.key = val } },
                onUpdateModel: { id, val in if let i = nodes.firstIndex(where: { $0.id == id }) { nodes[i].data.model = val } },
                onUpdateInputs: { id, val in if let i = nodes.firstIndex(where: { $0.id == id }) { nodes[i].data.inputs = val } },
                onPreviewImage: { urlOrBase64 in
                    if urlOrBase64.hasPrefix("base64:") {
                        previewBase64Image = String(urlOrBase64.dropFirst(7))
                    } else {
                        previewImageURL = urlOrBase64
                    }
                },
                onDelete: { id in
                    let children = nodes.filter { $0.parentId == id }.map(\.id)
                    nodes.removeAll { $0.id == id || children.contains($0.id) }
                    edges.removeAll { $0.source == id || $0.target == id || children.contains($0.source) || children.contains($0.target) }
                },
                onRename: { id in
                    let n = nodes.first(where: { $0.id == id })
                    editNodeLabel = n?.data.label.isEmpty == false ? n!.data.label : (FlowNodeType(rawValue: n?.type ?? "")?.title ?? "")
                    editingNodeId = id
                }
            )
        } overlay: {
            Background(variant: .lines, color: Color.borderMid.opacity(0.3), gap: 40)
            Controls(showZoom: true, showFitView: true, position: .bottomLeft)
            MiniMap(
                nodeColorMapper: { props in
                    if runtime.computingNodes.contains(props.id) { return .greenAccent }
                    if let n = nodes.first(where: { $0.id == props.id }), n.type == "macroNode" { return .cyanAccent }
                    return Color(red: 0.247, green: 0.294, blue: 0.349)
                },
                position: .bottomRight
            )
        }
        .contextMenu { addNodeContextMenu }
    }

    // MARK: - Add Node Context Menu

    @ViewBuilder
    private var addNodeContextMenu: some View {
        let addableTypes: [(String, [FlowNodeType])] = [
            ("Input", [.inputText, .inputImage]),
            ("Processing", [.customScript, .httpRequest, .jsonPath]),
            ("Output", [.outputText, .outputImage]),
            ("Macro", [.macroNode]),
        ]
        let insideMacro = currentView != nil
        let macroTypes: [(String, [FlowNodeType])] = [
            ("Ports", [.macroInEdge, .macroInParam, .macroOutput, .macroConnections]),
        ]

        ForEach(addableTypes, id: \.0) { group in
            Section(group.0) {
                ForEach(group.1, id: \.self) { type in
                    Button {
                        addNodeAtMousePosition(type: type)
                    } label: {
                        Label(type.title, systemImage: type.systemImage)
                    }
                }
            }
        }

        if insideMacro {
            ForEach(macroTypes, id: \.0) { group in
                Section(group.0) {
                    ForEach(group.1, id: \.self) { type in
                        Button {
                            addNodeAtMousePosition(type: type)
                        } label: {
                            Label(type.title, systemImage: type.systemImage)
                        }
                    }
                }
            }
        }
    }

    private func addNodeAtMousePosition(type: FlowNodeType) {
        #if canImport(AppKit)
        // Get mouse position relative to the window and convert to flow coordinates
        if let window = NSApp.keyWindow {
            let mouseInWindow = window.mouseLocationOutsideOfEventStream
            let flipped = CGPoint(x: mouseInWindow.x, y: window.contentView!.frame.height - mouseInWindow.y)
            // Subtract top bar height (~45px)
            let canvasPoint = CGPoint(x: flipped.x, y: flipped.y - 45)
            let flowPos = canvasScreenToFlow(canvasPoint)
            addNode(type: type, at: flowPos)
        } else {
            addNode(type: type)
        }
        #else
        addNode(type: type)
        #endif
    }

    // MARK: - Rename Modal

    private var renameModal: some View {
        ZStack {
            Color.canvasBg.opacity(0.8).ignoresSafeArea()
                .onTapGesture { editingNodeId = nil }

            VStack(spacing: 16) {
                Text("RENAME NODE")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(.cyanAccent)
                    .tracking(2)

                TextField("", text: $editNodeLabel)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.white)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(Color.canvasBg)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.borderMid))
                    .onSubmit { saveRename() }

                HStack {
                    Spacer()
                    Button("CANCEL") { editingNodeId = nil }
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.textMuted)
                        .buttonStyle(.plain)

                    Button(action: saveRename) {
                        Text("SAVE")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.canvasBg)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.cyanAccent)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(24)
            .frame(width: 320)
            .background(Color.nodeBg)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.borderDim))
            .shadow(color: .black.opacity(0.5), radius: 20)
        }
    }

    private func saveRename() {
        if let id = editingNodeId, let i = nodes.firstIndex(where: { $0.id == id }) {
            nodes[i].data.label = editNodeLabel
        }
        editingNodeId = nil
    }

    // MARK: - Image Preview

    private var imagePreviewOverlay: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()
                .onTapGesture {
                    previewImageURL = nil
                    previewBase64Image = nil
                }

            if let base64 = previewBase64Image {
                #if canImport(AppKit)
                if let commaIdx = base64.firstIndex(of: ","),
                   let data = Data(base64Encoded: String(base64[base64.index(after: commaIdx)...])),
                   let nsImg = NSImage(data: data) {
                    Image(nsImage: nsImg)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(40)
                }
                #endif
            } else if let url = previewImageURL {
                AsyncImage(url: URL(string: url)) { img in
                    img.resizable().aspectRatio(contentMode: .fit)
                } placeholder: {
                    ProgressView().tint(.white)
                }
                .padding(40)
            }

            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        previewImageURL = nil
                        previewBase64Image = nil
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.15))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .padding(20)
                }
                Spacer()
            }
        }
    }

    // MARK: - Add Node

    private func addNode(type: FlowNodeType, at position: XYPosition? = nil) {
        let id = "\(type.rawValue)_\(Int.random(in: 1000...9999))"
        let pos = position ?? XYPosition(x: 300, y: 300)
        let newNode = FNode(
            id: id,
            position: pos,
            data: FlowNodeData(label: type.title),
            type: type.rawValue,
            parentId: currentView
        )
        nodes.append(newNode)
    }

    private func canvasScreenToFlow(_ screenPoint: CGPoint) -> XYPosition {
        let zoom = max(instance.viewport.zoom, 0.1)
        return XYPosition(
            x: (screenPoint.x - instance.viewport.x) / zoom,
            y: (screenPoint.y - instance.viewport.y) / zoom
        )
    }
}
```

## Key Concepts Demonstrated

- **`import SwiftFlow`** — Required alongside `import SwiftUI` for all SwiftFlow types.
- **`FlowEdge<EmptyEdgeData>`** — The canonical type alias for `Edge`. When both `SwiftUI` and `SwiftFlow` are imported, the module `SwiftFlow` and the struct `SwiftFlow` (the canvas view) share the same name, making `Edge` ambiguous with `SwiftUI.Edge`. Use `FlowEdge<EmptyEdgeData>` or fully qualify as `SwiftFlow.Edge<EmptyEdgeData>`.
- **Node data model** — Typed `FlowNodeData` with an enum `NodeCategory` for per-node styling and icon selection.
- **Connection handles** — Every node declares a `.target` (input) handle on the left and a `.source` (output) handle on the right.
- **Selection styling** — Nodes show a colored border and enhanced shadow when selected; handles glow in the node's tint color.
- **Overlay components** — Dot-grid background, zoom/fit controls (bottom-left), and interactive minimap (bottom-right).
- **Default edge options** — New connections use `smoothstep` paths with filled arrowheads.

## Requirements

| Platform | Minimum Version |
|----------|-----------------|
| iOS      | 16.0+           |
| macOS    | 13.0+           |
| Swift    | 6.1+            |

SwiftFlow is a **zero-dependency** library — no third-party packages beyond Apple's frameworks.
