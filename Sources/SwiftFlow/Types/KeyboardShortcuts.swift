import Foundation

/// Configurable keyboard shortcuts for the SwiftFlow canvas.
///
/// Override defaults by creating a custom configuration:
/// ```swift
/// var shortcuts = KeyboardShortcuts.default
/// shortcuts.deleteKeyCode = 51  // Backspace
/// ```
public struct KeyboardShortcuts: Equatable, Sendable {
    /// Key code for deleting selected elements (default: 51 = Backspace).
    public var deleteKeyCode: UInt16
    /// Key code for forward-delete (default: 117).
    public var forwardDeleteKeyCode: UInt16
    /// Nudge distance without modifier (default: 1pt).
    public var nudgeDistance: CGFloat
    /// Nudge distance with shift held (default: 10pt).
    public var shiftNudgeDistance: CGFloat

    public init(
        deleteKeyCode: UInt16 = 51,
        forwardDeleteKeyCode: UInt16 = 117,
        nudgeDistance: CGFloat = 1,
        shiftNudgeDistance: CGFloat = 10
    ) {
        self.deleteKeyCode = deleteKeyCode
        self.forwardDeleteKeyCode = forwardDeleteKeyCode
        self.nudgeDistance = nudgeDistance
        self.shiftNudgeDistance = shiftNudgeDistance
    }

    public static let `default` = KeyboardShortcuts()
}
