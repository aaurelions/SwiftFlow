import SwiftUI

/// Preference key for propagating handle types (source/target) through the view hierarchy.
public struct HandleTypePreferenceKey: PreferenceKey {
  public static let defaultValue: [String: HandleType] = [:]

  public static func reduce(
    value: inout [String: HandleType], nextValue: () -> [String: HandleType]
  ) {
    value.merge(nextValue()) { current, _ in current }
  }
}
