import SwiftUI
import Testing

@testable import SwiftFlow

@Suite("SwiftFlowTheme")
struct ThemeTests {

  @Test func defaultTheme() {
    let theme = SwiftFlowTheme.default
    #expect(theme.edgeWidth == 2)
    #expect(theme.edgeSelectedWidth == 3)
    #expect(theme.handleSize == 12)
    #expect(theme.nodeSelectedBorderWidth == 2)
    #expect(theme.snapLineWidth == 1)
  }

  @Test func darkTheme() {
    let theme = SwiftFlowTheme.dark
    // Dark theme should have different colors from default
    #expect(theme.edgeWidth == 2)
  }

  @Test func lightTheme() {
    let theme = SwiftFlowTheme.light
    #expect(theme.edgeWidth == 2)
  }

  @Test func customTheme() {
    var theme = SwiftFlowTheme.default
    theme.edgeWidth = 5
    theme.handleSize = 20
    #expect(theme.edgeWidth == 5)
    #expect(theme.handleSize == 20)
  }

  @Test func themeEquatable() {
    let a = SwiftFlowTheme.default
    let b = SwiftFlowTheme.default
    #expect(a == b)

    var c = SwiftFlowTheme.default
    c.edgeWidth = 999
    #expect(a != c)
  }
}
