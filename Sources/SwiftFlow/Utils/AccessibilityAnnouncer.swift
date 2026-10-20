import SwiftUI

#if canImport(UIKit)
  import UIKit
#elseif canImport(AppKit)
  import AppKit
#endif

/// Posts VoiceOver announcements for canvas events.
///
/// Selection announcements are debounced so a selection box that changes on
/// every drag step produces a single announcement once it settles.
@MainActor
final class AccessibilityAnnouncer {
  private var pendingAnnouncement: Task<Void, Never>?

  /// Announces `message` now, or after `delay` if no newer message replaces it.
  func announce(_ message: String, after delay: Duration? = nil) {
    pendingAnnouncement?.cancel()
    guard Self.isVoiceOverRunning, !message.isEmpty else { return }
    guard let delay else {
      Self.post(message)
      return
    }
    pendingAnnouncement = Task { @MainActor in
      try? await Task.sleep(for: delay)
      guard !Task.isCancelled else { return }
      Self.post(message)
    }
  }

  private static var isVoiceOverRunning: Bool {
    #if canImport(UIKit)
      UIAccessibility.isVoiceOverRunning
    #elseif canImport(AppKit)
      NSWorkspace.shared.isVoiceOverEnabled
    #else
      false
    #endif
  }

  private static func post(_ message: String) {
    #if canImport(UIKit)
      UIAccessibility.post(notification: .announcement, argument: message)
    #elseif canImport(AppKit)
      NSAccessibility.post(
        element: NSApp.mainWindow ?? NSApp as Any,
        notification: .announcementRequested,
        userInfo: [
          .announcement: message,
          .priority: NSAccessibilityPriorityLevel.high.rawValue,
        ])
    #endif
  }
}
