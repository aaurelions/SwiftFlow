import SwiftUI

public struct NodeSizePreferenceKey: PreferenceKey {
  public static let defaultValue: [String: CGSize] = [:]

  public static func reduce(value: inout [String: CGSize], nextValue: () -> [String: CGSize]) {
    value.merge(nextValue()) { current, _ in current }
  }
}
