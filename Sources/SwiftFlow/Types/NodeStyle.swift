import SwiftUI

/// Visual style overrides for an individual node.
///
/// Set properties to `nil` to use the theme defaults. Only non-nil values
/// override the default appearance.
public struct NodeStyle: Equatable, Sendable, Hashable {
    public var backgroundColor: Color?
    public var borderColor: Color?
    public var borderWidth: CGFloat?
    public var borderRadius: CGFloat?
    public var opacity: Double?

    public init(
        backgroundColor: Color? = nil,
        borderColor: Color? = nil,
        borderWidth: CGFloat? = nil,
        borderRadius: CGFloat? = nil,
        opacity: Double? = nil
    ) {
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.borderRadius = borderRadius
        self.opacity = opacity
    }
}
