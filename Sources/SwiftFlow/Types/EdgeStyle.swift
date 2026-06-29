import SwiftUI

/// Visual style overrides for an individual edge.
///
/// Set properties to `nil` to use the theme defaults. Only non-nil values
/// override the default appearance.
public struct EdgeStyle: Equatable, Sendable, Hashable {
    public var strokeColor: Color?
    public var strokeWidth: CGFloat?
    public var opacity: Double?

    public init(
        strokeColor: Color? = nil,
        strokeWidth: CGFloat? = nil,
        opacity: Double? = nil
    ) {
        self.strokeColor = strokeColor
        self.strokeWidth = strokeWidth
        self.opacity = opacity
    }
}
