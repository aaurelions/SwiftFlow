import SwiftUI

/// Renders content at a specific flow (canvas) coordinate position.
///
/// Content placed inside a `ViewportPortal` is positioned in flow coordinates
/// and transforms with the viewport (pan/zoom).
///
/// ```swift
/// ViewportPortal(viewport: viewport) {
///     Text("Annotation")
///         .position(x: 100, y: 200) // Flow coordinates
/// }
/// ```
public struct ViewportPortal<Content: View>: View {
    public var viewport: Viewport
    @ViewBuilder public var content: () -> Content

    public init(
        viewport: Viewport,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.viewport = viewport
        self.content = content
    }

    public var body: some View {
        content()
            .scaleEffect(viewport.zoom, anchor: .topLeading)
            .offset(x: viewport.x, y: viewport.y)
    }
}
