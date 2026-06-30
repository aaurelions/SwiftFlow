import Foundation

/// Controls the color scheme used by SwiftFlow components.
public enum ColorMode: String, Sendable, Equatable {
  /// Light mode theme.
  case light
  /// Dark mode theme.
  case dark
  /// Follows the system appearance.
  case system
}
