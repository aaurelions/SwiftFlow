import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - Platform Colors

extension Color {
    /// The default canvas background color, adapting to the platform appearance.
    static var swiftFlowBackground: Color {
        #if canImport(UIKit)
        Color(uiColor: .systemGroupedBackground)
        #elseif canImport(AppKit)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color.gray.opacity(0.1)
        #endif
    }
}

// MARK: - View Helpers

extension View {
    @ViewBuilder
    func `if`<T: View>(_ condition: Bool, transform: (Self) -> T) -> some View {
        if condition { transform(self) } else { self }
    }
}

// MARK: - Cursor Helpers

#if canImport(AppKit)
/// Cursor types for interactive flow elements.
public enum FlowCursor {
    case grab, grabbing, pointer, crosshair, `default`

    var nsCursor: NSCursor {
        switch self {
        case .grab:      return .openHand
        case .grabbing:  return .closedHand
        case .pointer:   return .pointingHand
        case .crosshair: return .crosshair
        case .default:   return .arrow
        }
    }
}

struct CursorOnHoverModifier: ViewModifier {
    let cursor: FlowCursor

    func body(content: Content) -> some View {
        content.onHover { hovering in
            if hovering {
                cursor.nsCursor.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

extension View {
    /// Sets the cursor when hovering over this view (macOS only).
    public func flowCursor(_ cursor: FlowCursor) -> some View {
        modifier(CursorOnHoverModifier(cursor: cursor))
    }
}
#else
public enum FlowCursor { case grab, grabbing, pointer, crosshair, `default` }

extension View {
    public func flowCursor(_ cursor: FlowCursor) -> some View { self }
}
#endif

// MARK: - SnapLine (internal model)

struct SnapLine {
    var start: CGPoint
    var end: CGPoint
}

// MARK: - Secondary Action (Context Menu Trigger)

#if canImport(AppKit)
struct SecondaryClickModifier: ViewModifier {
    let action: () -> Void

    func body(content: Content) -> some View {
        content.overlay(SecondaryClickView(action: action))
    }
}

/// Monitors right-clicks via a local event monitor while passing through
/// all left-click, drag, and hover events to underlying SwiftUI content.
private struct SecondaryClickView: NSViewRepresentable {
    let action: () -> Void

    func makeNSView(context: Context) -> SecondaryClickNSView {
        let view = SecondaryClickNSView()
        view.action = action
        return view
    }

    func updateNSView(_ nsView: SecondaryClickNSView, context: Context) {
        nsView.action = action
    }

    final class SecondaryClickNSView: NSView {
        var action: (() -> Void)?
        private var eventMonitor: Any?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            removeMonitor()
            guard window != nil else { return }
            eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.rightMouseDown]) {
                [weak self] event in
                guard let self, let action = self.action else { return event }
                guard event.window == self.window else { return event }
                let locationInView = self.convert(event.locationInWindow, from: nil)
                guard self.bounds.contains(locationInView) else { return event }
                action()
                return event
            }
        }

        private func removeMonitor() {
            if let monitor = eventMonitor {
                NSEvent.removeMonitor(monitor)
                eventMonitor = nil
            }
        }

        override func hitTest(_ point: NSPoint) -> NSView? {
            nil  // pass-through: let SwiftUI views handle all mouse events
        }
    }
}
#elseif canImport(UIKit)
struct SecondaryClickModifier: ViewModifier {
    let action: () -> Void

    func body(content: Content) -> some View {
        content.overlay(LongPressView(action: action))
    }
}

private struct LongPressView: UIViewRepresentable {
    let action: () -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        let recognizer = UILongPressGestureRecognizer(
            target: context.coordinator, action: #selector(Coordinator.handleLongPress(_:)))
        view.addGestureRecognizer(recognizer)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.action = action
    }

    func makeCoordinator() -> Coordinator { Coordinator(action: action) }

    class Coordinator: NSObject {
        var action: () -> Void
        init(action: @escaping () -> Void) { self.action = action }
        @objc func handleLongPress(_ sender: UILongPressGestureRecognizer) {
            if sender.state == .began { action() }
        }
    }
}
#endif

extension View {
    func onSecondaryAction(perform action: @escaping () -> Void) -> some View {
        modifier(SecondaryClickModifier(action: action))
    }
}

// MARK: - macOS Scroll Wheel Handling

#if canImport(AppKit)
struct ScrollWheelModifier: ViewModifier {
    let onScroll: (CGFloat, CGPoint) -> Void

    func body(content: Content) -> some View {
        content.overlay(ScrollWheelView(onScroll: onScroll))
    }
}

/// Monitors scroll-wheel events via a local event monitor while passing through
/// all left-click, drag, and hover events to underlying SwiftUI content.
private struct ScrollWheelView: NSViewRepresentable {
    let onScroll: (CGFloat, CGPoint) -> Void

    func makeNSView(context: Context) -> ScrollWheelNSView {
        let view = ScrollWheelNSView()
        view.onScroll = onScroll
        return view
    }

    func updateNSView(_ nsView: ScrollWheelNSView, context: Context) {
        nsView.onScroll = onScroll
    }

    final class ScrollWheelNSView: NSView {
        var onScroll: ((CGFloat, CGPoint) -> Void)?
        private var eventMonitor: Any?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            removeMonitor()
            guard window != nil else { return }
            eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) {
                [weak self] event in
                guard let self, let onScroll = self.onScroll else { return event }
                guard event.window == self.window else { return event }
                let location = self.convert(event.locationInWindow, from: nil)
                guard self.bounds.contains(location) else { return event }

                // Ignore scroll events that accompany right-click or context menu
                guard event.phase != [] || !event.hasPreciseScrollingDeltas else {
                    let delta = event.scrollingDeltaY
                    guard abs(delta) > 0.5 else { return event }
                    onScroll(delta, location)
                    return nil  // consume
                }
                let delta = event.scrollingDeltaY
                guard abs(delta) > 0.1 else { return event }
                if event.hasPreciseScrollingDeltas {
                    onScroll(delta, location)
                } else {
                    onScroll(delta * 10, location)
                }
                return nil  // consume
            }
        }

        private func removeMonitor() {
            if let monitor = eventMonitor {
                NSEvent.removeMonitor(monitor)
                eventMonitor = nil
            }
        }

        override func hitTest(_ point: NSPoint) -> NSView? {
            nil  // pass-through: let SwiftUI views handle all mouse events
        }
    }
}

extension View {
    func onScrollWheel(_ handler: @escaping (CGFloat, CGPoint) -> Void) -> some View {
        modifier(ScrollWheelModifier(onScroll: handler))
    }
}
#endif

// MARK: - macOS Key Handling

#if canImport(AppKit)
struct KeyDownHandler: NSViewRepresentable {
    let handler: (NSEvent) -> Bool

    func makeNSView(context: Context) -> KeyView {
        let view = KeyView()
        view.handler = handler
        return view
    }

    func updateNSView(_ nsView: KeyView, context: Context) {
        nsView.handler = handler
    }

    class KeyView: NSView {
        var handler: ((NSEvent) -> Bool)?
        override var acceptsFirstResponder: Bool { true }
        override func keyDown(with event: NSEvent) {
            if handler?(event) != true { super.keyDown(with: event) }
        }
    }
}

extension View {
    func onKeyDown(_ handler: @escaping (NSEvent) -> Bool) -> some View {
        background(KeyDownHandler(handler: handler))
    }
}
#endif
