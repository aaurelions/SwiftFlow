import Foundation

/// The pattern drawn on the canvas background.
public enum BackgroundVariant: Equatable, Sendable {
    /// Regular dot grid pattern.
    case dots
    /// Horizontal and vertical line grid.
    case lines
    /// Cross-hair pattern at each grid intersection.
    case cross
}
