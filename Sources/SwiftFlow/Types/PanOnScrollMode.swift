import Foundation

/// Controls the panning direction when using scroll gestures.
///
/// - `free`: Pan freely in any direction.
/// - `vertical`: Restrict panning to the vertical axis.
/// - `horizontal`: Restrict panning to the horizontal axis.
public enum PanOnScrollMode: String, Equatable, Sendable, Codable, Hashable {
  case free
  case vertical
  case horizontal
}
