import SwiftUI

/// A single button for use inside `Controls` or as a standalone control.
///
/// ```swift
/// ControlButton(action: { print("tapped") }) {
///     Image(systemName: "plus")
/// }
/// ```
public struct ControlButton<Content: View>: View {
    public var action: () -> Void
    @ViewBuilder public var content: () -> Content

    public init(
        action: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.action = action
        self.content = content
    }

    public var body: some View {
        Button(action: action) {
            content()
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
