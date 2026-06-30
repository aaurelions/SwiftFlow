import Foundation

/// Platform-agnostic key code representation for keyboard shortcuts.
///
/// Wraps a raw `UInt16` key code with named constants for common keys.
///
/// ```swift
/// var shortcuts = KeyboardShortcuts.default
/// shortcuts.deleteKeyCode = KeyCode.backspace.rawValue
/// ```
public struct KeyCode: Equatable, Hashable, Sendable {
  public let rawValue: UInt16

  public init(_ rawValue: UInt16) {
    self.rawValue = rawValue
  }

  // MARK: - Common Key Codes (macOS virtual key codes)

  /// Backspace key (delete backward).
  public static let backspace = KeyCode(51)
  /// Forward delete key.
  public static let forwardDelete = KeyCode(117)
  /// Escape key.
  public static let escape = KeyCode(53)
  /// Return / Enter key.
  public static let `return` = KeyCode(36)
  /// Tab key.
  public static let tab = KeyCode(48)
  /// Space bar.
  public static let space = KeyCode(49)

  // MARK: - Arrow Keys

  /// Left arrow key.
  public static let leftArrow = KeyCode(123)
  /// Right arrow key.
  public static let rightArrow = KeyCode(124)
  /// Down arrow key.
  public static let downArrow = KeyCode(125)
  /// Up arrow key.
  public static let upArrow = KeyCode(126)

  // MARK: - Modifier Keys

  /// Command key.
  public static let command = KeyCode(55)
  /// Shift key.
  public static let shift = KeyCode(56)
  /// Option / Alt key.
  public static let option = KeyCode(58)
  /// Control key.
  public static let control = KeyCode(59)

  // MARK: - Letter Keys

  public static let a = KeyCode(0)
  public static let c = KeyCode(8)
  public static let v = KeyCode(9)
  public static let x = KeyCode(7)
  public static let z = KeyCode(6)
}

extension KeyCode: ExpressibleByIntegerLiteral {
  public init(integerLiteral value: UInt16) {
    self.rawValue = value
  }
}
